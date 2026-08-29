#!/usr/bin/env bash
# /etc/profile.d/kotlin.sh — Kotlin language fragment (kotlindev)
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Sourced by login shells via /etc/profile. Kept OUT of the user's chezmoi
# dotfiles so those stay pristine and langdev-agnostic. Sets the Kotlin
# environment for the pre-installed OpenJDK 21, Kotlin standalone compiler,
# Gradle, Maven, and Kotlin Language Server. Safe to re-source (idempotent).

# JDK environment (OpenJDK 21 on Alpine musl).
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

# Relocatable toolchain prefixes baked into /opt/langdev/toolchain.
export KOTLIN_HOME=/opt/langdev/toolchain/kotlinc
export GRADLE_HOME=/opt/langdev/toolchain/gradle
export MAVEN_HOME=/opt/langdev/toolchain/maven

# Prepend the toolchain paths if not already present.
for dir in "${JAVA_HOME}/bin" "/opt/langdev/toolchain/bin" "${KOTLIN_HOME}/bin" "${GRADLE_HOME}/bin" "${MAVEN_HOME}/bin"; do
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
done
export PATH

# --- Aliases (only for tools actually present in the image) -------------------
alias kc='kotlinc'
alias kr='kotlin'
alias ks='kotlinc -script'
alias kb='gradle build'
alias kt='gradle test'
alias krun='gradle run'
alias mvn-b='mvn clean package'
alias mvn-t='mvn test'
