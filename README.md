# Nix flake package for artemis

## Quick Use

```shell
nix shell github:espeon011/artemis-flake
```

## Using from flake.nix

```nix
{
  description = "artemis execution environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    artemis-flake = {
      url = "github:espeon011/artemis-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, artemis-flake }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "my-artemis-project";
          packages = [
            artemis-flake.packages.${system}.artemis
          ];
        };
      }
    );
}
```
