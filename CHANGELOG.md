# Changelog

All notable changes to `kotlindev` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-08-29

### Added
- Initial release of `kotlindev` on the unified `langdev` v2 multi-stage foundation.
- Full Kotlin 2.1+ toolchain: standalone compiler (`kotlinc`, `kotlin`), OpenJDK 21, Gradle, and Maven.
- Kotlin Language Server (`kotlin-language-server`) and Neovim integration.
- 4-pane TMUX IDE grid layout with `Prefix + i`.
- Parallel AI task worktree manager (`muxtree`, `Prefix + m`).
- Model Context Protocol (MCP) server (`/usr/local/bin/mcp-server`) with `common/mcp.json`.
- AI context packer (`ai-pack`) for rapid LLM prompt generation.
- WebTTY (`make web` / `make web-auth`) and Mosh roaming shell (`make mosh`).
- `make doctor` diagnostic CLI.
- Universal clipboard (OSC 52).
- Floating Lazygit (`Prefix + g`) and Lazydocker (`Prefix + d`) popups.
- Hermetic Bats unit test suite with kcov coverage gate.
- Hardened security defaults: non-root `dev` user, read-only rootfs, `cap_drop: [ALL]`, `no-new-privileges:true`.
