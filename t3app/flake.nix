{
  description = "Development environment for T3App project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "t3app-dev";

          buildInputs = with pkgs; [
            nodejs_22

            pnpm

            postgresql
            prisma-engines

            git

            just
            nodePackages.typescript
            nodePackages.typescript-language-server

            nodePackages.prettier
          ];

          shellHook = ''
            export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
            export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
            export PRISMA_INTROSPECTION_ENGINE_BINARY="${pkgs.prisma-engines}/bin/introspection-engine"
            export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"

            echo "T3App development environment ready!"
            echo "Installed tools:"
            echo " - Node.js $(node --version)"
            echo " - pnpm $(pnpm --version)"
            echo " - PostgreSQL $(psql --version)"
          '';
        };
      }
    );
}
