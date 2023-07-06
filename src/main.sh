#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schemaFile="$1"

# Check that a schema file was passed
if [ -z "$schemaFile" ]; then
  usage
fi

# Check that the schema file exists
if [ ! -f "$schemaFile" ]; then
  echo "Schema file not found: $schemaFile" 1>&2
  exit 1
fi

# Pass to lexer
schemaTokens=($(./src/lexer.sh <"$schemaFile"))

echo "Finished lexing, found ${#schemaTokens[@]} tokens:"
printf -- "- %s\n" "${schemaTokens[@]}"
