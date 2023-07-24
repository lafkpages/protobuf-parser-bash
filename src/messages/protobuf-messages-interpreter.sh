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

  if [ "$token" = "{" ]; then
    messageJson="$messageJson{"
  elif [ "$token" = "}" ]; then
    messageJson="$messageJson},"
  elif [[ "$token" =~ $fieldNameRegex ]]; then
    if [ "$nextToken" = ":" ]; then
      messageJson="$messageJson\"$token\":"

      # Get the field number from the schema
      fieldNumber="${schemaMessageFields["$messageType.$token"]}"

      # Get the field type from the schema
      fieldType="${schemaMessageTypes["$messageType.$fieldNumber"]}"

      # Get the enum for this field type
      if [ -n "$fieldType" ]; then
        fieldEnum="${schemaEnums["$fieldType"]}"
      else
        fieldEnum=""
      fi

      echo "${schemaEnums[@]} ${!schemaEnums[@]} ${schemaEnums["$fieldType"]}"
      echo "$token is of type $fieldType: enum $fieldEnum"

      # If the next token is an object,
      # let it be parsed later on
      if [ "$nextNextToken" = "{" ]; then
        messageJson="$messageJson{"
        skipNextIter="1"

      # If it's an enum, wrap it in quotes
      # and apply it directly
      elif [ -n "$fieldEnum" ]; then
        messageJson="$messageJson\"$nextNextToken\","
        skipNextIter="2"

      # Otherwise, apply it directly
      else
        messageJson="$messageJson$nextNextToken,"
        skipNextIter="2"
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
