############### BASIC MYSQL SESSION IMPLEMENTATION FOR BASH (by Norman Geist 2015) #############
# requires coproc, stdbuf, mysql
#args: handle query
# Modified by Dzogovic Vehbo (dzove855) 2019-01-21

[public:assoc] MYSQL

Mysql::check(){
    ps -p "$MYSQLCONNECTION_PID" &>/dev/null || return 1

    return 0
}

Mysql::connect(){
    [private] user="${MYSQL["connection":"user"]}" 
    [private] password="${MYSQL["connection":"password"]}"
    [private] host="${MYSQL["connection":"host"]:-localhost}" 
    [private] db="${MYSQL["connection":"database"]}"
    [private] port="${MYSQL["connecyion":"port"]:-3306}"

    Type::variable::set user password host db || { echo "No valid credentials"; return 1;}

    #init connection and channels
    coproc MYSQLCONNECTION { stdbuf -oL mysql -u $user -p$password -h $host -P $port -D $db --force --unbuffered ; } #2> /dev/null

    if Mysql::check; then
        return 0
    else
        echo "ERROR: Connection failed to $user@$host->DB:$db!"
        return 1
    fi
}

#args: handle query
#return: $array[result:ROW:columnName] = value
Mysql::query(){
    [private] query 
    [private] line 
    [private:map] array="$1"
    [private:int] counter="0"

    Mysql::check || Mysql::connect || return 1

    #delimit query; otherwise we block forever/timeout
    query="${2%;}\G;\\! echo 'END'"

    #send query
    echo "$query" >&${MYSQLCONNECTION[1]}

    #get output
    array[status]=0
    while read -t ${MYSQL_READ_TIMEOUT:-30} -ru ${MYSQLCONNECTION[0]} line; do 
        #WAS ERROR?
        if [[ "$line" == *"ERROR"* ]]; then
            echo "$line"
            return 1
        #WAS INSERT/UPDATE?
        elif [[ "$line" == *"Query OK"* ]]; then
            [[ "$line" =~ Query\ OK\,\ ([0-9]+)\ rows?\ affected ]] && array[status:affected]="${BASH_REMATCH[1]}"
            return 0
        elif [[ "$line" =~ .*[[:space:]]([0-9]*).[[:space:]]row.* ]]; then
                counter="${BASH_REMATCH[1]}"
        elif [[ "$line" == "END" ]]; then
            return 
        else
            result="${line#*:}"
            trim result
            array['result':$counter:${line%%:*}]="${result}"
        fi

    done

    #we can only get here
    #if read times out O_o
    echo "$FUNCNAME: Read timed out!"
    return 1
}

#args: handle
Mysql::close(){
    if ! Mysql::check; then
        echo "ERROR: Connection not open!"
        return 1
    fi

    echo "exit;" >&${MYSQLCONNECTION[1]}
}

Mysql::get(){
    [private] array="$1"
    [private] query="${*:2}"

    # Check if query is select
    [[ "$query" =~ ^(select|SELECT).* ]] || return 1

    Mysql::query "$array" "$query"
}

Mysql::post(){
    [private] array="$1"
    [private] query="${*:2}"
    [private:assoc] tmpArray
    read insert into table tmp <<<"$query"

    # check if query is really an insert
    [[ "$query" =~ ^(insert|INSERT).* ]] || return 1

    Mysql::query tmpArray "$query"
    Mysql::query "$array" "select * from $table where id=LAST_INSERT_ID()"
}

Mysql::put(){
    [private] array="$1"
    [private] query="${*:2}"
    [private:assoc] tmpArray
    [private] whereClause
    read update table tmp <<<"$query"    

    # check if query is update
    [[ "$query" =~ ^(update|UPDATE).* ]] || return 1

    [[ "$query" =~ .*(where|WHERE)(.*) ]] && whereClause="${BASH_REMATCH[2]}"

    Mysql::query tmpArray "$query"
    Mysql::query "$array" "select * from $table where $whereClause"
}

Mysql::delete(){
    [private] array="$1"
    [private] query="${*:2}"
    [private:assoc] tmpArray
    [private] whereClause
    read delete from table tmp <<<"$query"

    [[ "$query" =~ ^(delete|DELETE).* ]] || return 1

    [[ "$query" =~ .*(where|WHERE)(.*) ]] && whereClause="${BASH_REMATCH[2]}"

    Mysql::query "$array" "select id from $table where $whereClause"
    Mysql::query tmpArray "$query"

}

Mysql::build::query::get(){
    [private:map] array="$1"
    [private] where
    [private] limit

    [[ -z "${array['table']}" ]] && return 1

    if ! [[ -z "${array['search':'column']}" ]]; then
        where="where ${array['search':'column']}"
        where+=" like '${array['search':'key']:-%}'"
    fi

    if ! [[ -z "${array['limit']}" ]]; then
        limit="limit ${array['limit']}"
    fi

    printf '%s' "select ${array['filter']:-*} from ${array['table']} $where $limit"
}

Mysql::build::query::delete(){
    [private:map] array="$1"
    
    [[ -z "${array['table']}" ]] && return 1
    [[ -z "${array['search':'column']}" ]] && return 1

    printf '%s' "delete from ${array['table']} where ${array['search':'column']} like '${array['search':'key']:-%}'"
}

Mysql::build::query::post(){
    [private:map] array="$1"
    [private] column
    [private] values

    [[ -z "${array['table']}" ]] && return 1

    for key in "${!array[@]}"; do
        [[ "$key" == "table" ]] && continue
        column+="\`$key\`,"
        values+="\"$( printf '%q' "${array[$key]}")\","
    done

    printf '%s' "insert into ${array['table']} (${column%,}) values (${values%,})"
}

Mysql::build::query::put(){
    [private:map] array="$1"
    [private] column
    [private] values

    [[ -z "${array['table']}" ]] && return 1
    [[ -z "${array['search':'column']}" ]] && return 1

    for key in "${!array[@]}"; do
        [[ "$key" == "table" ]] && continue
        [[ "$key" =~ search.* ]] && continue

        update+="\`$key\`=\"$( printf '%q' "${array[$key]}")\","
    done
    
    printf '%s' "update ${array['table']} set ${update%,} where ${array['search':'column']} like '${array['search':'key']:-%}'"
}
