#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

# Call the lexer on the message
echo "Lexing message..."
source ./src/messages/protobuf-messages-lexer.sh

# Log lexer results
echo "Finished lexing, found ${#messageTokens[@]} tokens:"
printf -- "- %s\n" "${messageTokens[@]}"
echo
