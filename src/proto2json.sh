#!/usr/bin/env bash

# This is a simpler utility for converting the result of decoding from `protoc`
# into JSON. This does not need a schema, so might return wrongly structured
# data sometimes, but it works as a simple and quick solution in most cases.

json='{'

isInString=0
isAfterColon=0
shouldSkipNlComma=0
isQuotingEnum=0

currentToken=""

while IFS="" read -n1 char; do
  if [ "$isInString" = 1 ]; then
    currentToken="$currentToken$char"

    if [ "$char" = '"' ]; then
      isInString=0
    fi
  else
    if [ "$isQuotingEnum" = 1 ] && [[ ! "$char" =~ [a-zA-Z_] ]]; then
      isQuotingEnum=0
      currentToken="$currentToken\""
    fi

    if [ "$char" = "\"" ]; then
      isInString=1
      currentToken="$currentToken$char"
    elif [ "$char" = " " ]; then
      :
    elif [ "$char" = "" ]; then
      if [ "$shouldSkipNlComma" = 1 ]; then
        json="$json$currentToken"
        shouldSkipNlComma=0
      else
        json="$json$currentToken,"
      fi
      currentToken=""
    elif [ "$char" = ':' ]; then
      json="$json\"$currentToken\":"
      currentToken=""
      isAfterColon=1
    elif [ "$char" = "{" ]; then
      json="$json\"$currentToken\":{"
      currentToken=""
      shouldSkipNlComma=1
    elif [ "$char" = "}" ]; then
      json="${json%,}}"
      currentToken=""
    else
      if [ "$isAfterColon" = 1 ]; then
        currentToken="$currentToken\"$char"
        isQuotingEnum=1
      else
        currentToken="$currentToken$char"
      fi
    fi
  fi

  if [ "$char" = ":" ] || [ "$char" = " " ]; then
    :
  else
    isAfterColon=0
  fi
done

json="${json%,}}"

# Get the path of this script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

jsonWithDupes=$(jq -Mnc --stream -f "$DIR/dupekeys.jq" <<<"$json")

if [ "$?" = 0 ]; then
  echo "$jsonWithDupes"
else
  echo "$json" 1>&2
  exit "$?"
fi
