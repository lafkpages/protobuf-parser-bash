#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema> <messageType>" 1>&2
  echo 1>&2
  echo "Example: $0 person.proto Person" 1>&2
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

messageType="$2"

# Check that a message type was passed
if [ -z "$messageType" ]; then
  echo "protobuf-messages-main: No message type specified" 1>&2
  echo 1>&2
  usage
fi

# Lex schema
source ./src/schema/protobuf-schema-lexer.sh

# Interpret schema
interpreterDebug="1"
source ./src/schema/protobuf-schema-interpreter.sh
unset interpreterDebug

# Check that specified message type exists
if [ -z "${schemaMessages["$messageType"]}" ]; then
  echo "protobuf-messages-main: Message type not found: $messageType" 1>&2
  echo 1>&2
  usage
fi

# Call the lexer on the message
echo "Lexing message..."
source ./src/messages/protobuf-messages-lexer.sh

# Log lexer results
echo "Finished lexing, found ${#messageTokens[@]} tokens:"
printf -- "- %s\n" "${messageTokens[@]}"
echo

# Interpret tokens
echo "Interpreting tokens..."
source ./src/messages/protobuf-messages-interpreter.sh

# Log interpreter results
echo "Finished parsing, got:"
echo "$messageJson"
