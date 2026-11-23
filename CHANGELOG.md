# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added
- Planning documentation: README, AGENTS, architecture, API specification, project structure, release process,
  PR template and one implementation guide per phase.
- Verified templates in `Docs/templates/` (SwiftLint with architecture-boundary rules, CI workflow, xcconfig secrets, `.gitignore`).

### Changed
- Phase order is now Foundation → Domain → API → Discovery → Search → Player, so the API layer can implement protocols the Domain defines.
