[public:assoc] REDIS

Redis::check() {
    ps -p "$REDISCONNECTION_PID" &>/dev/null || return 1

    return 0
}

Redis::connect() {
    #[private] password="${REDIS["connection":"password"]:-sofian}"
    [private] host="${REDIS['connection':'host']:-127.0.0.1}"
    [private] db="${REDIS['connection':'database']:-0}"
    [private] port="${REDIS['connection':'port']:-6379}"

    Type::variable::set host db port || { echo "No valid credentials"; return 1;}

    coproc REDISCONNECTION { stdbuf -oL redis-cli -h $host -p $port; }
    #redis-cli -h $host -p $port

    if Redis::check; then
	echo "Redis connect is ok"
	return 0
    else
	echo "REDIS Connection Failed To $host:$port"
	return 1
    fi
}

Redis::readTest() {
    [private] query="$2"
    [private] line
    [private:assoc] array="$1"
    
    Redis::check || Redis::connect || return 1
    
    echo "$query" >&${REDISCONNECTION[1]}


    echo "okokokkookok2 $query"
    
    my_array=()
    while read -ru ${REDISCONNECTION[0]} line;
    do
	my_array+=( "$line" )
	echo "$line"
    done
}

Redis::query() {
    [private] query="$2"
    [private] key="${*:2}"
    [private] line
    [private:assoc] array="$1"
   
    Redis::check || Redis::connect || return 1

    #echo "this is the query $query"

    echo "$query" >&${REDISCONNECTION[1]}

    #set key value timeout : ok (review timeout)
    #get key : ok
    #select int : ok
    #del key : ok
    #lindex : ok
    
    #keys value : (review read multiple line)
    
    #rpush key value
    #lpush key value
    #lrange key int int
    #SSS : the lib is almost finish, i just have a probleme with read when i have multiple line to get from stdout of redis, i just got the first line and i don't find how to get more
    array[status]=0
    
    #status 1 = set
    #status 2 = get
    #status 3 = empty
    #status 4 = database
    
    while read -ru ${REDISCONNECTION[0]} line;
    do
	
	if [[ ! -z "$line"  && "$line" != *"OK"* ]]; then #get return null if bad query
	    echo "in if GET"
	    echo "je suis la "
	    if [[ "$line" =~ (.*db=([0-9]+)) ]]; then
		array['result':database]="${BASH_REMATCH[2]}"
       		array[status:affected]=4
		echo "test select database ${array['result':database]}"
		return 0
	    fi

	    array['result':$key]="$line" && array[status:affected]=2
	    echo "array with get == ${array['result':$key]}"
	    return 0

	elif [[ "$line" == *"OK"* ]]; then #set return ok
	    array[status:affected]=1
	    return 0
	  
	elif [[ -z "$line" ]]; then
	    keyDelete="${key##* }"
	    array['result':$key]="$keyDelete" && array[status:affected]=3
	    [[ "$query" =~ ^(get|GET).* ]] && echo "${array['result':$key]} is empty"

	    return 0
	    
	else
	    echo "error return redis::query"

	    return 1
	fi
    done
}

Redis::close() {
    if ! Redis::check; then
	echo "Error: Connection is not open"
	return 1
    fi
    echo "redis close is ok || exit" <&${REDISCONNECTION[1]}
}

Redis::get() {
    [private] array="$1"
    [private] query="${*:1}"

    [[ "$query" =~ ^(get|GET).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::post() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read set key value timeout <<<"$query"

    [[ "$query" =~ ^(set|SET).* ]] || return 1


    Redis::query tmpArray "$query" 
    Redis::query "$array" "get $key"
}

Redis::delete() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read del key <<<"$query"

    [[ "$query" =~ ^(DEL|del).* ]] || return 1

    echo "Redis::delete is ok"
    Redis::query tmpArray "$query"
    Redis::query "$array" "get $key"
}

Redis::select::database(){
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    
    [[ "$query" =~ ^(select|SELECT).* ]] || return 1

    Redis::query tmpArray "$query"
    Redis::query "$array" "client list"
}

Redis::keys() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read keys pattern <<<"$query"

    [[ "$query" =~ ^(keys|KEYS).* ]] || return 1

    Redis::readTest tmpArray "$query"
    #Redis::query tmpArray "$query"
    #Redis::query "$array" "get"
}

Redis::list::rpush() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read rpush key <<<"$query"
    
    [[ "$query" =~ ^(rpush|RPUSH).* ]] || return 1

    Redis::query tmpArray "$query"
    Redis::query "$array" "get $key"
}

Redis::list::lpush() {
    [private] array="$1"
    [private] query="${*:2}"

    [[ "$query" =~ ^(lpush|LPUSH).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::list::lrange() {
    [private] array="$1"
    [private] query="${*:1}"
    
    [[ "$query" =~ ^(lrange|LRANGE).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::list::lindex() {
    [private] array="$1"
    [private] query="${*:1}"

    echo "fdddp $query"
    
    [[ "$query" =~ ^(lindex|LINDEX).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::hash::hmset() {
    [private] array="$1"
    [private] query="${*:2}"

    [[ "$query" =~ ^(hmset|HMSET).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::hash::hget() {
    [private] array="$1"
    [private] query="${*:2}"

    [[ "$query" =~ ^(hget|HGET).* ]] || return 1

    Redis::query "$array" "$query"
}

Redis::hash::hgetall() {
    [private] array="$1"
    [private] query="${*:2}"

    [[ "$query" =~ ^(hgetall|HGETALL).* ]] || return 1

    Redis::query "$array" "$query"
}
