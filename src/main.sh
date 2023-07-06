#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schemaFile="$1"

if [ -z "$schemaFile" ]; then
  usage
fi

if [ ! -f "$schemaFile" ]; then
  echo "Schema file not found: $schemaFile" 1>&2
  exit 1
fi

# Pass to lexer
schemaTokens=($(./src/lexer.sh <"$schemaFile"))

echo "Finished lexing, found ${#schemaTokens[@]} tokens:"
printf -- "- %s\n" "${schemaTokens[@]}"
