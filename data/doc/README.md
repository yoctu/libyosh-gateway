## Data
This lib will provide functions like Data::get, Data::post, Data::put, Data::delete, Data::build::query::post, Data::build::query::put, to be the same, even if the backend is different.

## Config
You can connect multiple gateway using a matcher.
With Matcher:
DATA[matcher:$MATCHER]="$connection" # For example mysql

Without Matcher:
DATA[connection]="$connection" # for example mysql

## Functions
### Data::get Data::post Data::put Data::delete
All functions use the same Arg
Arguments: array query (Optional: Matcher)

It will return an array with the Data provided by the gateway

### Data::build::query::post Data::build::query::put
All functions use the same Arg
Arguments: array (Optional: Matcher)

It will return the builded query as a string
