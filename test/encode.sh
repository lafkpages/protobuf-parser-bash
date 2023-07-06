#!/usr/bin/env bash

# Encodes test/message.txt into test/message.bin,
# using the schema in test/example.proto.

protoc --encode=example.File test/example.proto < test/message.txt > test/message.bin

