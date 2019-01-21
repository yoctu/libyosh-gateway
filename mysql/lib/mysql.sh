############### BASIC MYSQL SESSION IMPLEMENTATION FOR BASH (by Norman Geist 2015) #############
# requires coproc, stdbuf, mysql
#args: handle query

Mysql::check(){
    local handle

    # add a check, ps?    

    return 0
}

Mysql::connect(){
    [private] user="${MYSQL["connection":"user"]}" 
    [private] password="${MYSQL["connection":"password"]}"
    [private] host="${MYSQL["connection":"host"]}" 
    [private] db="${MYSQL["connection":"database"]}"

    Type::variable::set user password host db || { echo "No valid credentials"; return 1;}

    #init connection and channels
    #we do it in XML cause otherwise we can't detect the end of data and so would need a read timeout O_o
    coproc MYSQLCONNECTION { stdbuf -oL mysql -u $user -p$password -h $host -D $db --force --unbuffered 2>&1; } #2> /dev/null

    if Mysql::check MYSQLCONNECTION; then
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
    [private] counter=0

    #delimit query; otherwise we block forever/timeout
    query="${2%;}\G;\\! echo 'END'"

    #send query
    echo "$query" >&${MYSQLCONNECTION[1]}

    #get output
    array[status]=0
    while read -t $MYSQL_READ_TIMEOUT -ru ${MYSQLCONNECTION[0]} line; do 
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
            array['result':$counter:${line%%:*}]="$result"
        fi

    done

    #we can only get here
    #if read times out O_o
    echo "$FUNCNAME: Read timed out!"
    return 1
}

#args: handle
Mysql::close(){

    if ! Mysql::check MYSQLCONNECTION; then
        echo "ERROR: Connection not open!"
        return 1
    fi

    echo "exit;" >&${MYSQLCONNECTION[1]}
}

