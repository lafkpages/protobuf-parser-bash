# protobuf-parser-bash

A Protobuf parser, encoder and decoder in Bash.

## Install

You'll need `protoc` for running some of the test scripts, but of course
you can use the library without it.

All you need to do is clone the repository:

```bash
git clone https://github.com/lafkpages/protobuf-parser-bash.git
cd protobuf-parser-bash
```

<!--
Or, use bpkg to install it:

```bash
bpkg install lafkpages/protobuf-parser-bash
```
-->

## Usage

Then, to lex and parse a `.proto` file, run:

```bash
./src/main.sh <path-to-proto-file>
```

You can try it with the [`test/example.proto`](#test/example.proto) file:

```bash
./src/main.sh test/example.proto
```

If you only want to lex the file into tokens, run:

```bash
./src/lexer.sh < <path-to-proto-file>
```

One token per line will be printed to stdout.

Note that here the file is passed via stdin, and not as an argument.
