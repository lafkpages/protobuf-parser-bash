#!/usr/bin/env bash

# This is meant to be sourced from src/main.sh

schemaSyntax=""
schemaPackage=""

schemaMessages=()
declare -A schemaMessageNames
declare -A schemaMessageTypes

schemaEnums=()
declare -A schemaEnumNames

isParsingMessage="0"
isParsingEnum="0"
isParsingField="0"

fieldBuiltinTypes=(
  double
  float
  int32
  int64
  uint32
  uint64
  sint32
  sint64
  fixed32
  fixed64
  sfixed32
  sfixed64
  bool
  string
  bytes
)
fieldTypes=($fieldBuiltinTypes)

skipNextIter="0"

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

for i in "${!schemaTokens[@]}"; do
  token="${schemaTokens[$i]}"
  nextToken="${schemaTokens[$i + 1]}"
  nextNextToken="${schemaTokens[$i + 2]}"
  nextNextNextToken="${schemaTokens[$i + 3]}"
  nextNextNextNextToken="${schemaTokens[$i + 4]}"

  if [ "$i" = "0" ] && [ "$token" != "syntax" ]; then
    echoErr "Expected 'syntax' as first token"
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

      # Save message
      schemaMessages+=("$messageName")

      echo "Parsed message $messageName with fields:"
      for fieldNumber in "${!messageFieldsNames[@]}"; do
        echo "- ${messageFieldsTypes["$fieldNumber"]} ${messageFieldsNames["$fieldNumber"]} = $fieldNumber"

        # Save field
        schemaMessageNames["$messageName.$fieldNumber"]="${messageFieldsNames["$fieldNumber"]}"
        schemaMessageTypes["$messageName.$fieldNumber"]="${messageFieldsTypes["$fieldNumber"]}"
      done
      echo

      continue
    fi

    if [ "$isParsingField" = "0" ]; then
      fieldType="$token"

      # Check that the token is a field type
      if [[ ! " ${fieldTypes[@]} " =~ " ${fieldType} " ]]; then
        echoErr "Expected field type (pos $((i + 1)))"
        exit 1
      fi

      isParsingField="1"
      fieldName="$nextToken"

      # Check that the next token is the field name
      if [[ ! "$fieldName" =~ $fieldNameRegex ]]; then
        echoErr "Expected message field name (pos $((i + 1)))"
        exit 1
      fi

      # Check that the next next token is an equals sign
      if [ "$nextNextToken" != "=" ]; then
        echoErr "Expected '=' after message field name (pos $((i + 2)))"
        exit 1
      fi

      # Check that the next next next token is a number
      if [[ ! "$nextNextNextToken" =~ ^[0-9]+$ ]]; then
        echoErr "Expected number after message field '=' (pos $((i + 3)))"
        exit 1
      fi

      fieldNumber="$nextNextNextToken"

      # Check that the next next next next token is a semicolon
      if [ "$nextNextNextNextToken" != ";" ]; then
        echoErr "Expected ';' after message field number (pos $((i + 4)))"
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
      echoErr "This should never happen"
      exit 1
    fi
  fi

  # If we're parsing an enum
  if [ "$isParsingEnum" = "1" ]; then
    # Check if we've reached the end of it
    if [ "$token" = "}" ]; then
      isParsingEnum="0"

      # Save enum
      schemaEnums+=("$enumName")

      echo "Parsed enum $enumName with fields:"
      for fieldNumber in "${!enumFields[@]}"; do
        echo "- ${enumFields["$fieldNumber"]} = $fieldNumber"

        # Save field
        schemaEnumNames["$enumName.$fieldNumber"]="${enumFields["$fieldNumber"]}"
      done
      echo

      continue
    fi

    if [ "$isParsingField" = "0" ]; then
      fieldName="$token"

      # Check that this token is the field name
      if [[ ! "$fieldName" =~ $fieldNameRegex ]]; then
        echoErr "Expected enum field name (pos $i)"
        exit 1
      fi

      isParsingField="1"

      # Check that the next token is an equals sign
      if [ "$nextToken" != "=" ]; then
        echoErr "Expected '=' after enum field name (pos $((i + 1)))"
        exit 1
      fi

      # Check that the next next token is a number
      fieldNumber="$nextNextToken"
      if [[ ! "$fieldNumber" =~ ^[0-9]+$ ]]; then
        echoErr "Expected number after enum field '=' (pos $((i + 2)))"
        exit 1
      fi

      # Check that the next next next token is a semicolon
      if [ "$nextNextNextToken" != ";" ]; then
        echoErr "Expected ';' after enum field number (pos $((i + 3)))"
        exit 1
      fi

      # Save field
      enumFields["$fieldNumber"]="$fieldName"

      # Skip next tokens
      skipNextIter="2"
    elif [ "$token" = ";" ]; then
      isParsingField="0"
    else
      echoErr "This should never happen"
      exit 1
    fi
  fi

  if [ "$token" = "syntax" ]; then
    # Check that the next token is an equals sign
    if [ "$nextToken" != "=" ]; then
      echoErr "Expected '=' after 'syntax'"
      exit 1
    fi

    # Check that the next next next token is a string
    if [ "${nextNextToken:0:1}" != "\"" ] || [ "${nextNextToken: -1}" != "\"" ]; then
      echoErr "Expected string after 'syntax ='"
      exit 1
    fi

    # Check that the next next next token is a semicolon
    if [ "$nextNextNextToken" != ";" ]; then
      echoErr "Expected ';' after 'syntax = \"...\"'"
      exit 1
    fi

    # Check that the syntax is proto3
    if [ "$nextNextToken" != "\"proto3\"" ]; then
      echoErr "Only proto3 syntax is supported"
      exit 1
    fi

    schemaSyntax="proto3"
  else
    # Check that the token is package
    case "$token" in
    package)
      if [ -z "$nextToken" ]; then
        echoErr "Expected package name after 'package'"
        exit 1
      fi

      schemaPackage="$nextToken"
      ;;

    message)
      messageName="$nextToken"

      # Nested messages are not supported yet
      if [ "$isParsingMessage" = "1" ]; then
        echoErr "Nested messages are not supported yet (pos $i)"
        exit 1
      fi

      if [ -z "$messageName" ] || [ "$messageName" = "{" ]; then
        echoErr "Expected message name after 'message' (pos $((i + 1)))"
        exit 1
      fi

      if [ "$nextNextToken" != "{" ]; then
        echoErr "Expected '{' after 'message $messageName' (pos $((i + 2)))"
        exit 1
      fi

      isParsingMessage="1"

      unset messageFieldsTypes messageFieldsNames
      declare -A messageFieldsTypes
      declare -A messageFieldsNames

      # Skip next token
      skipNextIter="2"

      ;;

    enum)
      enumName="$nextToken"

      if [ -z "$enumName" ] || [ "$enumName" = "{" ]; then
        echoErr "Expected enum name after 'enum' (pos $((i + 1)))"
        exit 1
      fi

      if [ "$nextNextToken" != "{" ]; then
        echoErr "Expected '{' after 'enum $enumName' (pos $((i + 2)))"
        exit 1
      fi

      isParsingEnum="1"

      unset enumFields
      declare -A enumFields

      # Skip next tokens
      skipNextIter="2"

      ;;
    esac
  fi
done

# Unset variables that are no longer needed
unset isParsingMessage messageName messageFieldsTypes \
  messageFieldsNames skipNextIter fieldTypes fieldType \
  fieldName fieldNumber enumFields token nextToken \
  nextNextToken nextNextNext nextNextNextNextToken \
  isParsingEnum isParsingField i echo
