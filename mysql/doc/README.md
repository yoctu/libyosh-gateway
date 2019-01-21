# MYSQL LIB 

This Lib keeps the mysql connection on, and return result as an array

## Mysql::connect
The Database credentials should be defined like this:
```
MYSQL['connection':'user']="USER"
MYSQL['connection':'password']="PASSWORD"
MYSQL['connection':'host']="HOST"
MYSQL['connection':'database']="DATABASE"
```

## Mysql::query
First argument should be the name of an associative array.
The second arg should be the query.

Result will be like this:
ARRAY[result:1:columnname]="value"

We start by on because we parse the \*\*\*\*\* 1. row \*\*\*\*\* 
