{
  description = "Astro.js development environment";

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
        in
        {
          devShells.default = pkgs.mkShell {
            name = "astro-dev";

            packages = with pkgs; [
              nodejs_22
              nodePackages.pnpm
              nodePackages.typescript
              nodePackages.typescript-language-server
              nodePackages.prettier
              git
            ];

            shellHook = ''
              echo "🚀 Astro development environment ready!"
              echo "Installed tools:"
              echo "  Node.js  $(node --version)"
              echo "  pnpm     $(pnpm --version)"
              echo "  TypeScript (tsc $(tsc --version | cut -d' ' -f2))"
              echo ""
              echo "Quick start:"
              echo "  pnpm create astro@latest"
            '';
          };
        };
    };
}
