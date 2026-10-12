#!/usr/bin/env bash
# Source this file to activate this cloud workspace's retained toolchain.
export XDG_DATA_HOME="${LUDO_DATA_HOME:-/workspace/.ludo-data}"
export XDG_CONFIG_HOME="${LUDO_CONFIG_HOME:-/workspace/.ludo-config}"
export XDG_CACHE_HOME="${LUDO_CACHE_HOME:-/workspace/.ludo-cache}"
export ANDROID_HOME="${LUDO_ANDROID_HOME:-/workspace/.ludo-tools/android-sdk}"
export ANDROID_USER_HOME="${LUDO_ANDROID_USER_HOME:-/workspace/.ludo-tools/android-user}"
export JAVA_HOME="${LUDO_JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$ANDROID_USER_HOME"
