#!/usr/bin/env bash

# This is meant to be sourced from src/messages/protobuf-messages-main.sh

echo() {
  if [ "$interpreterDebug" = "1" ]; then
    builtin echo "$@"
  fi
}

echoErr() {
  builtin echo "$@" 1>&2
  builtin echo "Current JSON: $messageJson" 1>&2
}

# Tokens that can be directly
# added to the JSON
jsonTokens=^[{}]$

skipNextIter="0"

messageJson="{"

for i in "${!messageTokens[@]}"; do
  token="${messageTokens[$i]}"
  nextToken="${messageTokens[$i + 1]}"
  nextNextToken="${messageTokens[$i + 2]}"
  nextNextNextToken="${messageTokens[$i + 3]}"
  nextNextNextNextToken="${messageTokens[$i + 4]}"

  # Ignore empty tokens.
  # This shouldn't happen, but handle it just in case.
  if [ -z "$token" ]; then
    echo "Warning: interpreter found an empty token"
    continue
  fi

  # Skip the next iteration if we're supposed to
  if [ "$skipNextIter" -gt 0 ]; then
    ((skipNextIter--))
    continue
  fi

  if [[ "$token" =~ $jsonTokens ]]; then
    messageJson="$messageJson$token"
  elif [[ "$token" =~ $fieldNameRegex ]]; then
    if [ "$nextToken" = ":" ]; then
      messageJson="$messageJson\"$token\":"

      # Get the field number from the schema
      fieldNumber="${schemaMessageFields["$messageType.$token"]}"

      # Get the field type from the schema
      fieldType="${schemaMessageTypes["$messageType.$fieldNumber"]}"

      # If the next token is a string, a number
      # or a boolean, add it directly
      if [ "$fieldType" = "string" ] || [ "$fieldType" = "bool" ] || [[ "$fieldType" =~ ^(double|float|int32|int64|uint32|uint64|sint32|sint64|fixed32|fixed64|sfixed32|sfixed64)$ ]]; then
        messageJson="$messageJson$nextNextToken,"
        skipNextIter="2"

      else
        skipNextIter="1"
      fi
    elif [ "$nextToken" = "{" ]; then
      messageJson="$messageJson\"$token\":{"
      skipNextIter="1"
    else
      echoErr "protobuf-messages-interpreter: expected ':' or '{' after field name, found '$nextToken'"
      exit 1
    fi
  fi
done

# Closing brace
messageJson="$messageJson}"

# Unset variables from interpreter
unset jsonTokens skipNextIter echo
