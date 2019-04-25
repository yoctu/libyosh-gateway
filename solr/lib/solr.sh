# Solr Bash implementation

[public:assoc] SOLR

Solr::build(){
    [[ -z "${SOLR['connection':'user']}" ]] || Curl::set::opt::auth::basic::user "${SOLR['connection':'user']}"
    [[ -z "${SOLR['connection':'password']}" ]] || Curl::set::opt::auth::basic::password "${SOLR['connection':'password']}"
    Curl::set::url "${SOLR['connection':'host']}"

    [[ -z "${CURL['get':'param':'q']}" ]] && Curl::set::get::param q "*:*"

    Curl::set::get::param "sort" "reported_at desc" 
}

Solr::get(){
    [private] array="$1"
    [private] query="$2"

    if ! [[ -z "$query" ]]; then
        if [[ "$query" =~ (.*)[[:space:]]#[[:space:]](.*) ]]; then
            Curl::set::get::param q "${BASH_REMATCH[1]}"
            Curl::set::get::param rows "${BASH_REMATCH[2]}"
        elif [[ "$query" =~ (.*)[[:space:]]#$ ]]; then
            Curl::set::get::param q "${BASH_REMATCH[1]}"
        elif ! [[ "$query" =~ .*#.* ]]; then
            Curl::set::get::param rows "${query#[[:space:]]}"
        fi
    fi

    Solr::build

    Json::to::array "$array" "{ \"result\" : $(Curl::run "solr/${SOLR['connection':'database']}/select" | jq -r .response.docs) }"
}

Solr::build::query::get(){
    [private:map] array="$1"

    if ! [[ -z "${array['search':'column']}" ]]; then
        printf '%s #' "${array['search':'column']:-*}:${array['search':'key']:-*}"
    fi

    if ! [[ -z "${array['limit']}" ]]; then
        printf ' %s' "${array['limit']}"
    fi


}


