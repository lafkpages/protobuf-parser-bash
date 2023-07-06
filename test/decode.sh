#!/usr/bin/env bash

# Decodes test/message.bin into test/message.txt,
# using the schema in test/example.proto.

protoc --decode=example.File test/example.proto < test/message.bin > test/message.txt
