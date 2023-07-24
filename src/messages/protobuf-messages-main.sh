#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

# Help arg
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
fi

schemaFile="$1"

# Check that a schema file was passed
if [ -z "$schemaFile" ]; then
  echo "protobuf-messages-main: No schema file specified" 1>&2
  echo 1>&2
  usage
fi

# Lex schema
source ./src/schema/protobuf-schema-lexer.sh

# Call the lexer on the message
echo "Lexing message..."
source ./src/messages/protobuf-messages-lexer.sh

# Log lexer results
echo "Finished lexing, found ${#messageTokens[@]} tokens:"
printf -- "- %s\n" "${messageTokens[@]}"
echo
