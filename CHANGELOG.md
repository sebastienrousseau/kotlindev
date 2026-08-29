# Changelog

All notable changes to `kotlindev` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.4] - 2026-08-29

### Added
- Unified `langdev` v0.0.4 suite release.
- Brand logo asset (`assets/logo.svg`).
- Single-page documentation website built with `ssg`.
- GitHub Pages automated deployment workflow.
- High performance < 500ms cold start guarantees and regression suite.

## [0.0.3] - 2026-08-29

### Added
- 4-pane TMUX IDE grid layout with `Prefix + i`.
- Parallel AI task worktree manager (`muxtree`, `Prefix + m`).
- Model Context Protocol (MCP) server (`/usr/local/bin/mcp-server`) with `common/mcp.json`.
- AI context packer (`ai-pack`) for rapid LLM prompt generation.
- WebTTY (`make web` / `make web-auth`) and Mosh roaming shell (`make mosh`).
- `make doctor` diagnostic CLI.
- Universal clipboard (OSC 52).
- Floating Lazygit (`Prefix + g`) and Lazydocker (`Prefix + d`) popups.

## [0.0.2] - 2026-08-29

### Added
- Hermetic Bats unit test suite with kcov coverage gate.
- Supply chain security hardening with CycloneDX SBOM and Trivy scanning.

## [0.0.1] - 2026-08-29

### Added
- Initial release of `kotlindev` on the multi-stage foundation.
- Full Kotlin 2.1+ toolchain: standalone compiler (`kotlinc`, `kotlin`), OpenJDK 21, Gradle, and Maven.
- Kotlin Language Server (`kotlin-language-server`) and Neovim integration.
- Hardened security defaults: non-root `dev` user, read-only rootfs, `cap_drop: [ALL]`, `no-new-privileges:true`.
