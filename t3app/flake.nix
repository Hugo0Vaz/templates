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

            openssl

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
            export OPENSSL_LIBDIR="${pkgs.openssl.out}/lib"
            export LD_LIBRARY_PATH="${pkgs.openssl.out}/lib:$LD_LIBRARY_PATH"

            export PGDATA="$PWD/data/pgdata"
            if [ ! -d "$PGDATA" ]; then
              echo "Creating PostgreSQL data directory in $PGDATA"
              initdb -D $PGDATA --no-locale --encoding=UTF8
            fi

            chmod 755 ./data

            echo "To run PostgreSQL run:"
            echo "pg_ctl -D $PGDATA -l ./data/log_file start"

            trap 'pg_ctl stop; echo "Postres process stopped!"' EXIT

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
