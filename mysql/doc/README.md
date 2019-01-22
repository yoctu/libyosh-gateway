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


## Mysql::get
Arguments: array query
This will check if the Query is a select, if not it return 1

## Mysql::post
Arguments: array query
This will check if the Query is an insert, if not it return 1
If yes it will return the inserted data in the array given in the argument based on Last_Insert_Id

## Mysql::put
Arguments: array query
This will check if the query is an update, if not it return 1
If yes it will return the updated data in the array given in the argument based on the whereclause

## Mysql::delete 
Arguments: array query
This will check if the query is an delete, if not it return 1
If yes it will return the id of the deleted data based on the whereclause

## Mysql::build::query::post
Arguments: array
It will create an insert query based on an array.
The array should be array[columname]="value"
You need to add a key table, with the tablename as value.

### Mysql::build::query::put
Arguments: array
It will create an update query based on an array.
The array should be array[columname]="value"
You need to add a key table, with the tablename as value and a ley whereclause with the where statement as a value.
