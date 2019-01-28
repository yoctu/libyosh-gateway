# Data Lib for using multiple gateways
[public:assoc] DATA

Data::runner(){
    [private] method="$1"
    [private] array="$2"
    Type::array::is::assoc "$array" || return 1

    [private] query="${3}"

    Type::variable::set method array query || return 1

    [private] matcher="$4"

    if [[ -z "$matcher" ]]; then
        Type::function::exist ${DATA['connection']^}::$method && ${DATA['connection']^}::$method "$array" "$query"
    else
        Type::function::exist ${DATA['matcher':$matcher]^}::$method && ${DATA['matcher':$matcher]^}::$method "$array" "$query"
    fi
}

Data::build::query(){
    [private] method="$1"
    [private] array="$2"
    [private] matcher="$3"

    Type::array::is::assoc "$array" || return 1

    if [[ -z "$matcher" ]]; then
        Type::function::exist ${DATA['connection']^}::build::query::$method && ${DATA['connection']^}::build::query$method "$array" 
    else
        Type::function::exist ${DATA['matcher':$matcher]^}::build::query::$method && ${DATA['matcher':$matcher]^}::build::query::$method "$array"
    fi
}

alias Data::get="Data::runner get"
alias Data::put="Data::runner put"
alias Data::post="Data::runner post"
alias Data::delete="Data::runner delete"
alias Data::build::query::post="Data::build::query post"
alias Data::build::query::put="Data::build::query put"
alias Data::build::query::delete="Data::build::query delete"
alias Data::build::query::get="Data::build::query get"

