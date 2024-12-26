{
  description = "Julia script runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        program = ''
          #!/usr/bin/env bash
          if [ $# -lt 1 ]; then
            echo "Usage: run-julia <script.jl> [args...]"
            exit 1
          fi
          
          SCRIPT="$1"
          shift
          
          JULIA_DEPOT_PATH=$(mktemp -d)
          trap 'rm -rf "$JULIA_DEPOT_PATH"' EXIT
          
          exec env JULIA_DEPOT_PATH="$JULIA_DEPOT_PATH" julia --startup-file=no "$SCRIPT" "$@"
        '';
      in
      {
        packages.default = pkgs.writeShellApplication {
          name = "run-julia";
          runtimeInputs = [ pkgs.julia-bin ];
          text = program;
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/run-julia";
        };
      });
}