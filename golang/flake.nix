{
  description = "Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          goVersion = pkgs.go_1_24;

          devTools = with pkgs; [
            goVersion
            gopls            # Official Go language server
            delve            # Debugger
            go-tools         # Static analysis (staticcheck, etc)
            golangci-lint    # Popular linter aggregator
            gomodifytags     # Go struct tags manipulation
            gotests          # Generate tests
            richgo           # Colorized `go test` output
            mockgen          # Generate mocks
            air              # Live reload for Go apps
            gofumpt          # Strict gofmt
            revive           # Fast linter
            govulncheck      # Vulnerability scanner
            sqlc             # SQL to Go type-safe codegen
            protobuf         # Protocol Buffers
            grpcurl          # gRPC debugging

            postgresql
          ];
        in
        {
          devShells.default = pkgs.mkShell {
            name = "golang-dev";

            packages = devTools;

            shellHook = ''
              trap 'pg_ctl stop; echo "Postres process stopped!"' EXIT

              export PGDATA="$PWD/data/pgdata"

              if [ ! -d "$PGDATA" ]; then
                echo "Creating PostgreSQL data directory in $PGDATA"
                initdb -D $PGDATA --no-locale --encoding=UTF8
              else
                echo "To run PostgreSQL run:"
                echo "pg_ctl -D $PGDATA -l ./data/log_file start"
              fi

              figlet "golang-dev"

              echo "Available tools:"
              echo "  golang, gopls, delve, go-tools, golangci-lint, air, sqlc, etc."
            '';
          };
        };
    };
}
