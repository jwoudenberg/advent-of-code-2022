{
  description = "groceries";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    roc.url = "github:kubukoz/roc/fix-nix";
  };
  outputs = { self, nixpkgs, flake-utils, roc }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShell =
          pkgs.mkShell { buildInputs = [ roc.packages."${system}".default ]; };
      });
}
