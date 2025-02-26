import json
import os


def load_config(filename="config/config.json"):
    try:
        with open(filename, "r") as file:
            return json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


CONFIG = load_config()
