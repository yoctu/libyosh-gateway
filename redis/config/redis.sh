#!/bin/bash

REDIS['connection':'password']="sofian"
REDIS["connection":"host"]="127.0.0.1"
REDIS["connection":"database"]="${REDIS_DATABASE:-0}"
REDIS["connection":"port"]="6379"
