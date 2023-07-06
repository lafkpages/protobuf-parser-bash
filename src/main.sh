#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schemaFile="$1"

if [ -z "$schemaFile" ]; then
  usage
fi

# Parse schema
schemaSyntax=""
schemaParserCurrentToken=""
schemaParserIsString="0"
schemaParserTokens=()
schemaParserOperators=("=" "{" "}" ";")
while read -n1 char; do
  if [ "$schemaParserIsString" = "1" ]; then
    if [ "$char" = "\"" ]; then
      schemaParserIsString="0"
      schemaParserTokens+=("$schemaParserCurrentToken\"")
    fi
    schemaParserCurrentToken="$schemaParserCurrentToken$char"
  else
    if [[ " ${schemaParserOperators[*]} " =~ " $char " ]]; then
      schemaParserTokens+=("$schemaParserCurrentToken")
      schemaParserTokens+=("$char")
      schemaParserCurrentToken=""
    elif [ "$char" = "\"" ]; then
      schemaParserIsString="1"
      schemaParserCurrentToken="\""
    elif [ "$char" = " " ]; then
      schemaParserTokens+=("$schemaParserCurrentToken")
      schemaParserCurrentToken=""
    else
      schemaParserCurrentToken="$schemaParserCurrentToken$char"
    fi
  fi

  echo "$schemaParserCurrentToken"
  echo "$schemaParserIsString"
  echo "${schemaParserTokens[@]}"
done < "$schemaFile"
