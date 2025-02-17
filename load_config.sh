#!/bin/bash

# load_config.sh

# Load the variables from config.env

# Check if config.env exists
if [[ ! -f "config.env" ]]; then
    echo "Error: File 'config.env' not found!"
    exit 1
fi

source config.env


