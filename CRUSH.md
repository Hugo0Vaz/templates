# CRUSH.md - Nix Development Environments

## Project Overview
Collection of Nix flake-based development environment templates for various tech stacks.

## Build/Test Commands
```bash
# Enter development environment for any template
nix develop ./[template-name]  # e.g., nix develop ./golang

# Build flake
nix build

# Update flake inputs
nix flake update

# Check flake validity
nix flake check
```

## Code Style Guidelines
- **Nix Files**: Use 2-space indentation, follow nixpkgs conventions
- **Structure**: Each environment in separate directory with own flake.nix
- **Naming**: Use lowercase directory names matching the technology stack
- **Imports**: Prefer explicit imports, avoid `with` statements where possible
- **Shell Hooks**: Include database initialization and cleanup in shellHook
- **Platform Support**: Always support x86_64/aarch64 for Linux and Darwin

## Environment-Specific Notes
- **Golang**: Uses air for hot reload, richgo for test output, golangci-lint for linting
- **T3App**: Uses pnpm, Prisma ORM, just task runner
- **Laravel**: PHP 8.2 with MariaDB socket connection
- **Jupyter**: Python 3.11 with virtual environment setup

## Common Patterns
- Exit trap handlers for cleanup: `trap cleanup EXIT`
- Database auto-initialization in shellHook
- Multi-platform support via flake-utils