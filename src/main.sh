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

# Check that the schema file has a .proto extension
if [ "${schemaFile: -6}" != ".proto" ]; then
  echo "Schema file must have a .proto extension: $schemaFile" 1>&2
  exit 1
fi

echo "Lexing $schemaFile..."

# Pass to lexer
schemaTokens=($(./src/lexer.sh <"$schemaFile"))

echo "Finished lexing, found ${#schemaTokens[@]} tokens:"
printf -- "- %s\n" "${schemaTokens[@]}"
echo

# Interpret tokens
source ./src/interpreter.sh

echo "Finished parsing, found:"
echo "- syntax: $schemaSyntax"
echo "- package: $schemaPackage"

echo "- messages:"
for message in "${schemaMessages[@]}"; do
  echo "  - $message:"
  for fieldKey in "${!schemaMessageNames[@]}"; do
    if [[ "$fieldKey" =~ (^$message\.(.+)$) ]]; then
      fieldNumber="${BASH_REMATCH[2]}"
      echo "    - ${schemaMessageTypes["$message.$fieldNumber"]} ${schemaMessageNames["$message.$fieldNumber"]} = $fieldNumber"
    fi
  done
done
