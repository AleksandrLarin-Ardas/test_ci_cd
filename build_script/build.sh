#!/bin/bash

BUILD_NAME="Local build 1.0.0"
BUILD_NO=3

flutter build apk --target=lib/main.dart \
  --build-name=$BUILD_NAME \
  --build-number=$BUILD_NO \
  --release