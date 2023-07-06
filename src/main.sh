#!/usr/bin/env bash

usage() {
  echo "Usage: $0 <schema>" 1>&2
  exit 1
}

schema="$1"

if [ -z "$schema" ]; then
  usage
fi
