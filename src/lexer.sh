#!/usr/bin/env bash

schemaParserCurrentToken=""
schemaParserIsString="0"
schemaParserTokens=()
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
      if [ -n "$schemaParserCurrentToken" ]; then
        schemaParserTokens+=("$schemaParserCurrentToken")
      fi
      schemaParserCurrentToken=""
    elif [ "$char" = "=" ] || [ "$char" = "{" ] || [ "$char" = "}" ] || [ "$char" = ";" ]; then
      if [ -n "$schemaParserCurrentToken" ]; then
        schemaParserTokens+=("$schemaParserCurrentToken")
      fi
      schemaParserTokens+=("$char")
      schemaParserCurrentToken=""
    elif [ "$char" = "\"" ]; then
      schemaParserIsString="1"
      schemaParserCurrentToken="\""
    else
      schemaParserCurrentToken="$schemaParserCurrentToken$char"
    fi
  fi
done

printf -- "%s\n" "${schemaParserTokens[@]}"
