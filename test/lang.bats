#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for dotfiles.d/kotlin.sh — the Kotlin language profile fragment
# installed to /etc/profile.d and sourced by login shells.
load helpers/common

setup() { common_setup; }

SCRIPT="dotfiles.d/kotlin.sh"

@test "kotlin.sh: sets the toolchain env and prepends bins to PATH" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    # shellcheck source=/dev/null
    source "$1"
    printf "JAVA_HOME=%s\n" "$JAVA_HOME"
    printf "KOTLIN_HOME=%s\n" "$KOTLIN_HOME"
    printf "GRADLE_HOME=%s\n" "$GRADLE_HOME"
    printf "MAVEN_HOME=%s\n" "$MAVEN_HOME"
    printf "PATHVAL=%s\n" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"JAVA_HOME=/usr/lib/jvm/java-21-openjdk"* ]]
  [[ "$output" == *"KOTLIN_HOME=/opt/langdev/toolchain/kotlinc"* ]]
  [[ "$output" == *"GRADLE_HOME=/opt/langdev/toolchain/gradle"* ]]
  [[ "$output" == *"MAVEN_HOME=/opt/langdev/toolchain/maven"* ]]
  [[ "$output" == *"/opt/langdev/toolchain/kotlinc/bin"* ]]
}

@test "kotlin.sh: is idempotent — re-sourcing does not duplicate the PATH entry" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    source "$1"; source "$1"
    printf "PATHVAL=%s" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  pathval="${output#PATHVAL=}"
  n="$(printf '%s' "$pathval" | grep -oF '/opt/langdev/toolchain/kotlinc/bin' | wc -l)"
  [ "$n" -eq 1 ]
}
