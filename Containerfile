# syntax=docker/dockerfile:1.9
# kotlindev Containerfile — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Multi-stage, hardened, ultra-small Kotlin dev image on the langdev foundation.
# The `toolchain` stage fetches + checksum-verifies the build tools (Kotlin compiler,
# Gradle, Maven) and the Kotlin Language Server into a single relocatable prefix
# (/opt/langdev/toolchain); the `final` stage installs musl OpenJDK 21 from Alpine
# and copies that prefix in.
#
# Pin the base by DIGEST. Update via `make bump-base`.
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Dotfiles source — "always the latest" by default; pin a tag/commit for reproducible builds.
ARG DOTFILES_REPO=https://github.com/sebastienrousseau/dotfiles.git
ARG DOTFILES_REF=main

###############################################################################
# Stage: toolchain  (LANGUAGE-SPECIFIC — Kotlin compiler + Gradle + Maven + KLS)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain

ARG KOTLIN_VERSION=2.1.10
ARG KOTLIN_SHA256=c6e9e2636889828e19c8811d5ab890862538c89dc2a3101956dfee3c2a8ba6b1
ARG KLS_VERSION=1.3.13
ARG KLS_SHA256=4fe7d71d087b307c7869036171bd9d8c6a4284cd7c25b89098b0a24eb2d9b6d2
ARG GRADLE_VERSION=9.7.1
ARG GRADLE_SHA256=acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a
ARG MAVEN_VERSION=3.9.16
ARG MAVEN_SHA512=831a8591fe20c8243b1dbe7d71e3244f31d1665b0804b2e825e38cbbe5ce0cafb8338851f90780735568773e0a6cd07bbec107cda0b896b008b861075358b6f6

ENV TOOLCHAIN=/opt/langdev/toolchain

# Build-only fetch/extract tools.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      tar \
      gzip \
      unzip \
 && update-ca-certificates

# 1. Kotlin Standalone Compiler (kotlinc, kotlin)
RUN set -eux; \
    url="https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip"; \
    curl -fsSL "$url" -o /tmp/kotlin.zip; \
    echo "${KOTLIN_SHA256}  /tmp/kotlin.zip" | sha256sum -c -; \
    mkdir -p "${TOOLCHAIN}"; \
    unzip -q /tmp/kotlin.zip -d "${TOOLCHAIN}"; \
    rm -f /tmp/kotlin.zip

# 2. Kotlin Language Server (KLS)
RUN set -eux; \
    url="https://github.com/fwcd/kotlin-language-server/releases/download/${KLS_VERSION}/server.zip"; \
    curl -fsSL "$url" -o /tmp/kls.zip; \
    echo "${KLS_SHA256}  /tmp/kls.zip" | sha256sum -c -; \
    unzip -q /tmp/kls.zip -d "${TOOLCHAIN}"; \
    mv "${TOOLCHAIN}/server" "${TOOLCHAIN}/kls"; \
    mkdir -p "${TOOLCHAIN}/bin"; \
    ln -sf "${TOOLCHAIN}/kls/bin/kotlin-language-server" "${TOOLCHAIN}/bin/kotlin-language-server"; \
    rm -f /tmp/kls.zip

# 3. Gradle
RUN set -eux; \
    url="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"; \
    curl -fsSL "$url" -o /tmp/gradle.zip; \
    echo "${GRADLE_SHA256}  /tmp/gradle.zip" | sha256sum -c -; \
    unzip -q /tmp/gradle.zip -d "${TOOLCHAIN}"; \
    mv "${TOOLCHAIN}/gradle-${GRADLE_VERSION}" "${TOOLCHAIN}/gradle"; \
    rm -f /tmp/gradle.zip

# 4. Maven
RUN set -eux; \
    url="https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"; \
    curl -fsSL "$url" -o /tmp/maven.tar.gz; \
    echo "${MAVEN_SHA512}  /tmp/maven.tar.gz" | sha512sum -c -; \
    tar -xzf /tmp/maven.tar.gz -C "${TOOLCHAIN}"; \
    mv "${TOOLCHAIN}/apache-maven-${MAVEN_VERSION}" "${TOOLCHAIN}/maven"; \
    rm -f /tmp/maven.tar.gz

RUN chmod -R 0755 "${TOOLCHAIN}"

###############################################################################
# Stage: env-build  (COMMON — apply the user's dotfiles + bake nvim plugins)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS env-build
ARG USERNAME USER_UID USER_GID DOTFILES_REPO DOTFILES_REF
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates chezmoi curl git \
      neovim ripgrep fd fzf bat \
      build-base cmake
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"
COPY --chown=${USER_UID}:${USER_GID} common/bootstrap-dotfiles.sh /usr/local/bin/langdev-bootstrap-dotfiles
RUN chmod 0755 /usr/local/bin/langdev-bootstrap-dotfiles
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
# 1) Clone + chezmoi-apply dotfiles.
RUN DOTFILES_REPO="${DOTFILES_REPO}" DOTFILES_REF="${DOTFILES_REF}" \
      langdev-bootstrap-dotfiles
# 2) Drop the Kotlin LSP spec into nvim and bake plugins headless.
COPY --chown=${USER_UID}:${USER_GID} nvim/plugins.local/ /home/${USERNAME}/.config/nvim/lua/plugins.local/
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+Lazy! sync"    +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync"  +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base
ARG USERNAME USER_UID USER_GID

LABEL org.opencontainers.image.title="kotlindev" \
      org.opencontainers.image.description="Portable, disposable Kotlin dev environment (langdev suite)" \
      org.opencontainers.image.licenses="Apache-2.0 OR MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      bat \
      ca-certificates \
      chezmoi \
      curl \
      fd \
      fzf \
      git \
      less \
      mosh-server \
      neovim \
      ripgrep \
      tini \
      tmux \
      ttyd \
      tzdata \
      zoxide \
 && update-ca-certificates

RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

COPY --from=env-build --chown=${USER_UID}:${USER_GID} /home/${USERNAME} /home/${USERNAME}

COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
COPY common/tmux-ide.sh /usr/local/bin/tmux-ide
COPY common/muxtree.sh /usr/local/bin/muxtree
COPY common/doctor.sh /usr/local/bin/langdev-doctor
COPY common/mcp-server.sh /usr/local/bin/mcp-server
COPY common/ai-pack.sh /usr/local/bin/ai-pack
COPY common/explorer.sh /usr/local/bin/langdev-explorer
COPY common/mcp.json /etc/langdev-mcp.json
COPY common/tmux.conf /etc/tmux.conf
RUN chmod 0755 /usr/local/bin/langdev-entrypoint /usr/local/bin/tmux-ide /usr/local/bin/muxtree \
               /usr/local/bin/langdev-doctor /usr/local/bin/mcp-server /usr/local/bin/ai-pack \
               /usr/local/bin/langdev-explorer \
 && chmod 0644 /etc/tmux.conf /etc/langdev-mcp.json \
 && mkdir -p /usr/local/lib/langdev

RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (Kotlin runtime — musl OpenJDK 21 + relocatable Kotlin/Gradle)
###############################################################################
FROM base AS final

# hadolint ignore=DL3018
USER root
RUN apk add --no-cache openjdk21 \
 && java -version

COPY --from=toolchain --chown=1000:1000 /opt/langdev/toolchain /opt/langdev/toolchain

COPY dotfiles.d/kotlin.sh /etc/profile.d/kotlin.sh
RUN chmod 0644 /etc/profile.d/kotlin.sh

USER dev

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk \
    KOTLIN_HOME=/opt/langdev/toolchain/kotlinc \
    GRADLE_HOME=/opt/langdev/toolchain/gradle \
    MAVEN_HOME=/opt/langdev/toolchain/maven \
    PATH=/usr/lib/jvm/java-21-openjdk/bin:/opt/langdev/toolchain/bin:/opt/langdev/toolchain/kotlinc/bin:/opt/langdev/toolchain/gradle/bin:/opt/langdev/toolchain/maven/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
