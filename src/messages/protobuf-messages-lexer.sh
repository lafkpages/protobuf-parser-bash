#!/usr/bin/env bash

# This is meant to be sourced from src/messages/protobuf-messages-main.sh

# Read message data
messageData=$(cat)

messageParserCurrentToken=""
messageParserIsString="0"
messageTokens=()
while IFS="" read -n1 char; do
  if [ "$messageParserIsString" = "1" ]; then
    messageParserCurrentToken="$messageParserCurrentToken$char"
    if [ "$char" = "\"" ]; then
      messageParserIsString="0"
      messageTokens+=("$messageParserCurrentToken")
      messageParserCurrentToken=""
    fi
  else
    if [ "$char" = ' ' ] || [ "$char" = $'\n' ]; then
      if [ -n "$messageParserCurrentToken" ]; then
        messageTokens+=("$messageParserCurrentToken")
      fi
      messageParserCurrentToken=""
    elif [ "$char" = "=" ] || [ "$char" = "{" ] || [ "$char" = "}" ] || [ "$char" = ";" ]; then
      if [ -n "$messageParserCurrentToken" ]; then
        messageTokens+=("$messageParserCurrentToken")
      fi
      messageTokens+=("$char")
      messageParserCurrentToken=""
    elif [ "$char" = "\"" ]; then
      messageParserIsString="1"
      messageParserCurrentToken="\""
    else
      messageParserCurrentToken="$messageParserCurrentToken$char"
    fi
  fi
done <<<"$messageData"

# Unset variables from lexer
unset messageData messageParserCurrentToken messageParserIsString
