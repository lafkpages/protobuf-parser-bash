#!/usr/bin/env bash

# This is meant to be sourced from src/main.sh

schemaSyntax=""
schemaPackage=""

declare -A schemaMessages

isParsingMessage="0"

for i in "${!schemaTokens[@]}"; do
  token="${schemaTokens[$i]}"
  nextToken="${schemaTokens[$i + 1]}"
  nextNextToken="${schemaTokens[$i + 2]}"
  nextNextNextToken="${schemaTokens[$i + 3]}"

  if [ "$i" = "0" ] && [ "$token" != "syntax" ]; then
    echo "Expected 'syntax' as first token" 1>&2
    exit 1
  fi

  # Ignore empty tokens.
  # This shouldn't happen, but handle it just in case.
  if [ -z "$token" ]; then
    continue
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

      if [ -z "$messageName" ] || [ "$messageName" = "{" ]; then
        echo "Expected message name after 'message'" 1>&2
        exit 1
      fi

      if [ "$nextNextToken" != "{" ]; then
        echo "Expected '{' after 'message $messageName'" 1>&2
        exit 1
      fi

      isParsingMessage="1"

      declare -A messageFields

      ;;
    esac
  fi
done
