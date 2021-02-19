#!/bin/sh

set -xe

MDBOOK_DOWNLOAD="https://github.com/rust-lang/mdBook/releases/download/v0.4.6/mdbook-v0.4.6-x86_64-unknown-linux-gnu.tar.gz"

mkdir -p ./bin
curl -L "$MDBOOK_DOWNLOAD" | tar -xvzC bin
./bin/mdbook build
