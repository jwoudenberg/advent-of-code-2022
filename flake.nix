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
        devShell = (pkgs.buildFHSUserEnv {
          name = "roc-in-fhs-userenv";
          targetPkgs = _: [ roc.packages."${system}".default ];
          runScript = "fish";
        }).env;
      });
}
