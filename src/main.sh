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

# Interpret tokens
schemaSyntax=""
schemaPackage=""
for i in "${!schemaTokens[@]}"; do
  token="${schemaTokens[$i]}"
  nextToken="${schemaTokens[$i + 1]}"
  nextNextToken="${schemaTokens[$i + 2]}"
  nextNextNextToken="${schemaTokens[$i + 3]}"

  if [ "$token" = "syntax" ]; then
    # Check that the next token is an equals sign
    if [ "$nextToken" != "=" ]; then
      echo "Expected '=' after 'syntax'" 1>&2
      exit 1
    fi

    # Check that the next next next token is a string
    if [ "${nextNextToken:0:1}" != "\"" ] || [ "${nextNextToken: -1}" != "\"" ]; then
      echo "Expected string after 'syntax ='" 1>&2
      exit 1
    fi

    # Check that the next next next token is a semicolon
    if [ "$nextNextNextToken" != ";" ]; then
      echo "Expected ';' after 'syntax = \"...\"'" 1>&2
      exit 1
    fi

    # Check that the syntax is proto3
    if [ "$nextNextToken" != "\"proto3\"" ]; then
      echo "Only proto3 syntax is supported" 1>&2
      exit 1
    fi

    schemaSyntax="proto3"
  else
    # No other tokens allowed before syntax
    if [ -z "$schemaSyntax" ]; then
      echo "Expected 'syntax = \"...\"'" 1>&2
      exit 1
    fi

    # Check that the token is package
    if [ "$token" = "package" ]; then
      if [ -z "$nextToken" ]; then
        echo "Expected package name after 'package'" 1>&2
        exit 1
      fi

      schemaPackage="$nextToken"
    fi
  fi
done

echo "Finished parsing, found:"
echo "- syntax: $schemaSyntax"
echo "- package: $schemaPackage"
