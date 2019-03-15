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

    if Redis::check; then
	echo "Redis connect is ok"
	return 0
    else
	echo "REDIS Connection Failed To $host:$port"
	return 1
    fi
}

Redis::query() {
    [private] query="$2"
    [private] key="${*:2}"
    [private] line
    [private:assoc] array="$1"
   
    Redis::check || Redis::connect || return 1

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
    
    array[status]=0
    
    #status 1 = set
    #status 2 = get
    #status 3 = empty
    #status 4 = database
    
    while read -ru ${REDISCONNECTION[0]} line;
    do	
	if [[ ! -z "$line"  && "$line" != *"OK"* ]]; then
	    if [[ "$line" =~ (.*db=([0-9]+)) ]]; then
		array['result':'database']="${BASH_REMATCH[2]}"
       		array[status:affected]=4
		return 0
	    fi
	    array['result':$key]="$line" && array[status:affected]=2
	    return 0

	elif [[ "$line" == *"OK"* ]]; then
	    array[status:affected]=1	    
	    return
	  
	elif [[ -z "$line" ]]; then
	    keyDelete="${key##* }"
	    array['result':$key]="$keyDelete" && array[status:affected]=3
	    [[ "$query" =~ ^(get|GET).* ]] && echo "${array['result':$key]} is empty or it was delete"
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

    Redis::query tmpArray "$query"
    Redis::query "$array" "get" #read multiple line error
}

Redis::list::rpush() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read rpush key <<<"$query"
    
    [[ "$query" =~ ^(rpush|RPUSH).* ]] || return 1

    Redis::query tmpArray "$query"
    Redis::query "$array" "get $key" #read multiple line error
}

Redis::list::lpush() {
    [private] array="$1"
    [private] query="${*:1}"
    [private:assoc] tmpArray
    read lpush list value <<<"$query"
    
    [[ "$query" =~ ^(lpush|LPUSH).* ]] || return 1

    Redis::query tmpArray "$query"
    Redis::query "$array" "lindex $list 0"
}

Redis::list::lrange() {
    [private] array="$1"
    [private] query="${*:1}"
    
    [[ "$query" =~ ^(lrange|LRANGE).* ]] || return 1

    Redis::query "$array" "$query" #read multiple line error
}

Redis::list::lindex() {
    [private] array="$1"
    [private] query="${*:1}"
    
    [[ "$query" =~ ^(lindex|LINDEX).* ]] || return 1

    Redis::query "$array" "$query" #error read  multiple line
}

Redis::build::query::get() {
    [private:map] array="$1"
    
    [[ -z "${array['table']}" ]] && return 1
    [[ -z "${array['search':'key']}" ]] && return 1
    
    printf '%s\n' "select ${array['table']}"
    printf '%s' "get ${array['search':'key']}"
}

Redis::build::query::post() {
    [private:map] array="$1"

    [[ -z "${array['table']}" ]] && return 1
    [[ -z "${array['search':'key']}" && -z "$array['search':'key':'value']" ]] && return 1

    printf '%s\n' "select ${array['table']}"
    if [[ "${array['timeout']}" -eq "0" ]]; then
	printf '%s' "set ${array['search':'key']} ${array['search':'key':'value']}"
    else
	printf '%s' "set ${array['search':'key']} ${array['search':'key':'value']} ex ${array['timeout']}"
    fi
}

Redis::build::query::delete() {
    [private:map] array="$1"

    [[ -z "${array['table']}" ]] && return 1
    [[ -z "${array['search':'key']}" ]] && return 1

    printf '%s\n' "select ${array['table']}"
    printf '%s' "del ${array['search':'key']}"
}
