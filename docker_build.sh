#!/bin/sh
if [ "$1" == "--build-image" ]
then
    (echo FROM alpine:latest && echo RUN apk --no-cache add ruby python3 zip) | docker build -t umineko -
elif [ -e "$UMINEKO_TARGET" ]
then
    docker run --rm -v "$(pwd)":/umineko -w /umineko -v "$UMINEKO_TARGET":/target -e UMINEKO_TARGET=/target umineko "./build.sh"
elif [ -e "$UMINEKO_TARGET_YUZU" ]
then
    docker run --rm -v "$(pwd)":/umineko -w /umineko -v "$UMINEKO_TARGET_YUZU":/target -e UMINEKO_TARGET_YUZU=/target umineko "./build.sh"
else
    docker run --rm -v "$(pwd)":/umineko -w /umineko umineko "./build.sh"
fi
