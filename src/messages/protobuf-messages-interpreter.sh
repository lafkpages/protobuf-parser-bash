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

# Field name RegEx
declare -r fieldNameRegex=^[a-zA-Z_][a-zA-Z0-9_]*$

# Tokens that can be directly
# added to the JSON
declare -r jsonTokens=^[{}]$

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

  # Turn the message into JSON.
  # An example message could look like this:
  #
  #   openChan {
  #     service: "exec"
  #     action: ATTACH_OR_CREATE
  #   }
  #   ref: "9erp4ql2h5"
  #
  # And we want to turn it into JSON that looks like this:
  #
  #   {
  #     "openChan": {
  #       "service": "exec",
  #       "action": "ATTACH_OR_CREATE"
  #     },
  #     "ref": "9erp4ql2h5"
  #   }

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
unset fieldNameRegex jsonTokens skipNextIter
