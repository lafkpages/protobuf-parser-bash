#!/usr/bin/env bash

schema="$1"

if [ -z "$schema" ]; then
  echo "Usage: $0 <schema>"
  exit 1
fi
