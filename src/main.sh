#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schemaFile="$1"

if [ -z "$schemaFile" ]; then
  usage
fi

# Load schema
schema=$(cat "$schemaFile")
