#!/usr/bin/env bash

# This is meant to be sourced from src/messages/protobuf-messages-main.sh

echo() {
  if [ "$interpreterDebug" = "1" ]; then
    builtin echo "$@"
  fi
}

echoErr() {
  builtin echo "$@" 1>&2
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
    if [ "$nextToken" != ":" ]; then
      echoErr "protobuf-messages-interpreter: expected ':' after field name, found '$nextToken'"
      exit 1
    fi

    messageJson="$messageJson\"$token\":"
  fi
done

# Unset variables from interpreter
unset jsonTokens skipNextIter
