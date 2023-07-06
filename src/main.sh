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

# Parse schema
schemaSyntax=""
schemaParserCurrentToken=""
schemaParserIsString="0"
schemaParserTokens=()
schemaParserOperators=("=" "{" "}" ";")
while IFS="" read -n1 char; do
  if [ "$schemaParserIsString" = "1" ]; then
    schemaParserCurrentToken="$schemaParserCurrentToken$char"
    if [ "$char" = "\"" ]; then
      schemaParserIsString="0"
      schemaParserTokens+=("$schemaParserCurrentToken")
      schemaParserCurrentToken=""
    fi
  else
    if [ "$char" = ' ' ] || [ "$char" = $'\n' ]; then
      schemaParserTokens+=("$schemaParserCurrentToken")
      schemaParserCurrentToken=""
    elif [[ " ${schemaParserOperators[*]} " =~ " $char " ]]; then
      schemaParserTokens+=("$schemaParserCurrentToken")
      schemaParserTokens+=("$char")
      schemaParserCurrentToken=""
    elif [ "$char" = "\"" ]; then
      schemaParserIsString="1"
      schemaParserCurrentToken="\""
    else
      schemaParserCurrentToken="$schemaParserCurrentToken$char"
    fi
  fi

  echo "$schemaParserCurrentToken"
  echo "$schemaParserIsString"
  echo "${schemaParserTokens[@]}"
done < "$schemaFile"

echo $'\n\n\n'
echo "Finished lexing, found ${#schemaParserTokens[@]} tokens:"
printf -- "- %s\n" "${schemaParserTokens[@]}"
