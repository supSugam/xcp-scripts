#!/bin/bash

if [[ ! -f ../config.env ]]; then
    echo "Error: config.env file not found!"
    exit 1
fi

# Load the variables
source ../config.env
