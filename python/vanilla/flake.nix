{
  description = "Python project with flake-parts + venv + requirements.txt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { config, self', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            python3Packages.venvShellHook
            python3Packages.pip
            just
          ];

          # Where the venv will live
          venvDir = ".venv";

          # Automatically create venv if missing
          postShellHook = ''
            if [ ! -d "$venvDir" ]; then
              python -m venv $venvDir
            fi

            source $venvDir/bin/activate

            echo "🐍 Python venv activated: $venvDir"
          '';
        };
      };
    };
}
