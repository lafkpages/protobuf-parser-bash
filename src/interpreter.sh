#!/usr/bin/env bash

# This is meant to be sourced from src/main.sh

schemaSyntax=""
schemaPackage=""

declare -A schemaMessages

isParsingMessage="0"
isParsingField="0"

fieldTypes=(string bytes number bool)

skipNextIter="0"

for i in "${!schemaTokens[@]}"; do
  token="${schemaTokens[$i]}"
  nextToken="${schemaTokens[$i + 1]}"
  nextNextToken="${schemaTokens[$i + 2]}"
  nextNextNextToken="${schemaTokens[$i + 3]}"
  nextNextNextNextToken="${schemaTokens[$i + 4]}"

  if [ "$i" = "0" ] && [ "$token" != "syntax" ]; then
    echo "Expected 'syntax' as first token" 1>&2
    exit 1
  fi

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

  # If we're parsing a message
  if [ "$isParsingMessage" = "1" ]; then
    # Check if we've reached the end of it
    if [ "$token" = "}" ]; then
      isParsingMessage="0"

      echo "Parsed message $messageName with fields:"
      for fieldNumber in "${!messageFieldsNames[@]}"; do
        echo "- ${messageFieldsTypes["$fieldNumber"]} ${messageFieldsNames["$fieldNumber"]} = $fieldNumber"
      done
      echo

      continue
    fi

    if [ "$isParsingField" = "0" ]; then
      fieldType="$token"

      # Check that the token is a field type
      if [[ ! " ${fieldTypes[@]} " =~ " ${fieldType} " ]]; then
        echo "Expected field type (pos $((i + 1)))" 1>&2
        exit 1
      fi

      isParsingField="1"
      fieldName="$nextToken"

      # Check that the next token is the field name
      if [[ ! "$fieldName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Expected message field name (pos $((i + 1)))" 1>&2
        exit 1
      fi

      # Check that the next next token is an equals sign
      if [ "$nextNextToken" != "=" ]; then
        echo "Expected '=' after message field name (pos $((i + 2)))" 1>&2
        exit 1
      fi

      # Check that the next next next token is a number
      if [[ ! "$nextNextNextToken" =~ ^[0-9]+$ ]]; then
        echo "Expected number after message field '=' (pos $((i + 3)))" 1>&2
        exit 1
      fi

      fieldNumber="$nextNextNextToken"

      # Check that the next next next next token is a semicolon
      if [ "$nextNextNextNextToken" != ";" ]; then
        echo "Expected ';' after message field number (pos $((i + 4)))" 1>&2
        exit 1
      fi

      # Save field
      messageFieldsTypes["$fieldNumber"]="$fieldType"
      messageFieldsNames["$fieldNumber"]="$fieldName"

      # Skip next tokens
      skipNextIter="3"
    elif [ "$token" = ";" ]; then
      isParsingField="0"
    else
      echo "This should never happen" 1>&2
      exit 1
    fi
  fi

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
    # Check that the token is package
    case "$token" in
    package)
      if [ -z "$nextToken" ]; then
        echo "Expected package name after 'package'" 1>&2
        exit 1
      fi

      schemaPackage="$nextToken"
      ;;

    message)
      messageName="$nextToken"

      # Nested messages are not supported yet
      if [ "$isParsingMessage" = "1" ]; then
        echo "Nested messages are not supported yet (pos $i)" 1>&2
        exit 1
      fi

      if [ -z "$messageName" ] || [ "$messageName" = "{" ]; then
        echo "Expected message name after 'message' (pos $((i + 1)))" 1>&2
        exit 1
      fi

      if [ "$nextNextToken" != "{" ]; then
        echo "Expected '{' after 'message $messageName' (pos $((i + 2)))" 1>&2
        exit 1
      fi

      isParsingMessage="1"

      unset messageFieldsTypes messageFieldsNames
      declare -A messageFieldsTypes
      declare -A messageFieldsNames

      # Skip next token
      skipNextIter="2"

      ;;
    esac
  fi
done

# Unset variables that are no longer needed
unset isParsingMessage messageName messageFieldsTypes \
  messageFieldsNames skipNextIter fieldTypes fieldType \
  fieldName fieldNumber
