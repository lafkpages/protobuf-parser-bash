#!/usr/bin/env bash

# /======================================================\
# | TODO:                                                |
# | https://bpkg.sh/guidelines/#package-exports          |
# \======================================================/

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schemaFile="$1"

# Check that a schema file was passed
if [ -z "$schemaFile" ]; then
  usage
fi

# Check that the schema file exists
if [ ! -f "$schemaFile" ]; then
  echo "Schema file not found: $schemaFile" 1>&2
  exit 1
fi

# Check that the schema file has a .proto extension
if [ "${schemaFile: -6}" != ".proto" ]; then
  echo "Schema file must have a .proto extension: $schemaFile" 1>&2
  exit 1
fi

# Pass to lexer
echo "Lexing $schemaFile..."
source ./src/protobuf-lexer.sh

# Log lexer results
echo "Finished lexing, found ${#schemaTokens[@]} tokens:"
printf -- "- %s\n" "${schemaTokens[@]}"
echo

# Interpret tokens
echo "Interpreting tokens..."
source ./src/protobuf-interpreter.sh

# Log interpreter results
echo "Finished parsing, found:"
echo "- syntax: $schemaSyntax"
echo "- package: $schemaPackage"
echo "- messages:"
for message in "${schemaMessages[@]}"; do
  echo "  - $message:"
  for fieldKey in "${!schemaMessageNames[@]}"; do
    if [[ "$fieldKey" =~ (^$message\.(.+)$) ]]; then
      fieldNumber="${BASH_REMATCH[2]}"
      echo "    - ${schemaMessageTypes["$message.$fieldNumber"]} ${schemaMessageNames["$message.$fieldNumber"]} = $fieldNumber"
    fi
  done
done
echo "- enums:"
for enum in "${schemaEnums[@]}"; do
  echo "  - $enum:"
  for enumKey in "${!schemaEnumNames[@]}"; do
    if [[ "$enumKey" =~ (^$enum\.(.+)$) ]]; then
      enumNumber="${BASH_REMATCH[2]}"
      echo "    - ${schemaEnumNames["$enum.$enumNumber"]} = $enumNumber"
    fi
  done
done
