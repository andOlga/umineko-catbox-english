@echo off

if "%1" == "--build-image" (
    (echo FROM alpine:latest && echo RUN apk --no-cache add ruby python3 zip) | docker build -t umineko -
    goto :end
)

if not "%UMINEKO_TARGET%" == "" (
    docker run --rm -v "%CD%":/umineko -w /umineko -v "%UMINEKO_TARGET%":/target -e UMINEKO_TARGET=/target umineko "./build.sh"
    goto :end
)

if not "%UMINEKO_TARGET_YUZU%" == "" (
    docker run --rm -v "%CD%":/umineko -w /umineko -v "%UMINEKO_TARGET_YUZU%":/target -e UMINEKO_TARGET_YUZU=/target umineko "./build.sh"
    goto :end
)

docker run --rm -v "%CD%":/umineko -w /umineko umineko "./build.sh"

:end
pause