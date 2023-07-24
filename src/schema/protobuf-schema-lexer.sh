#!/usr/bin/env bash

# This is meant to be sourced from src/schema/protobuf-schema-main.sh

# Ensure that schemaFile is set
if [ -z "$schemaFile" ]; then
  echo "protobuf-lexer: \$schemaFile is not set" 1>&2
  exit 1
fi

# Read proto file and remove comments and blank lines
schemaData=$(sed 's/\/\/.*//' <"$schemaFile")

schemaParserCurrentToken=""
schemaParserIsString="0"
schemaTokens=()
while IFS="" read -n1 char; do
  if [ "$schemaParserIsString" = "1" ]; then
    schemaParserCurrentToken="$schemaParserCurrentToken$char"
    if [ "$char" = "\"" ]; then
      schemaParserIsString="0"
      schemaTokens+=("$schemaParserCurrentToken")
      schemaParserCurrentToken=""
    fi
  else
    if [ "$char" = ' ' ] || [ "$char" = $'\n' ]; then
      if [ -n "$schemaParserCurrentToken" ]; then
        schemaTokens+=("$schemaParserCurrentToken")
      fi
      schemaParserCurrentToken=""
    elif [ "$char" = "=" ] || [ "$char" = "{" ] || [ "$char" = "}" ] || [ "$char" = ";" ]; then
      if [ -n "$schemaParserCurrentToken" ]; then
        schemaTokens+=("$schemaParserCurrentToken")
      fi
      schemaTokens+=("$char")
      schemaParserCurrentToken=""
    elif [ "$char" = "\"" ]; then
      schemaParserIsString="1"
      schemaParserCurrentToken="\""
    else
      schemaParserCurrentToken="$schemaParserCurrentToken$char"
    fi
  fi
done <<<"$schemaData"

# Unset variables from lexer
unset schemaData schemaParserCurrentToken schemaParserIsString
