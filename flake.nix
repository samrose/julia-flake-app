{
  description = "Julia data processing application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        program = ''
          #!/usr/bin/env julia
          
          using Pkg
          Pkg.add(["DataFrames", "CSV"])
          using DataFrames, CSV

          abstract type DataSource end
          abstract type TextSource <: DataSource end
          abstract type BinarySource <: DataSource end

          struct CSVSource <: TextSource
              path::String
          end

          struct JSONSource <: TextSource
              path::String
          end

          function read_data(source::CSVSource)
              CSV.read(source.path, DataFrame)
          end

          function read_data(source::JSONSource)
              error("JSON not implemented")
          end

          abstract type Operation end
          struct Summarize <: Operation end
          struct FilterOp <: Operation
              column::Symbol
              value::Any
          end

          function process(df::DataFrame, op::Summarize)
              describe(df)
          end

          function process(df::DataFrame, op::FilterOp)
              filter(row -> row[op.column] == op.value, df)
          end

          function main()
              if length(ARGS) < 1
                  println("Usage: process-data <csv-file>")
                  exit(1)
              end

              df = read_data(CSVSource(ARGS[1]))
              println("Data sample:")
              println(first(df, 5))
              
              println("\nSummary:")
              println(process(df, Summarize()))
          end

          if abspath(PROGRAM_FILE) == @__FILE__
              main()
          end
        '';
      in
      {
        packages.default = pkgs.writeScriptBin "process-data" program;

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/process-data";
        };
      });
}