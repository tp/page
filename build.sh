#!/bin/sh

set -eux
cd PageCMS
rm -rf ../dist/*
swift build
./.build/x86_64-apple-macosx10.10/debug/PageCMS

cp -r ../assets/ ../dist/assets/

ls ../dist/
