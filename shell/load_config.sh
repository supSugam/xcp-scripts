#!/bin/bash

# load_config.sh

# Load the variables from config.env at the root of the project

# Check if config.env exists there
if [[ ! -f ../config.env ]]; then
    echo "Error: config.env file not found!"
    exit 1
fi

# Load the variables
source ../config.env
