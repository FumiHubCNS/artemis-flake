# Nix flake package for artemis

This is a flake for the [artemis](https://github.com/artemis-dev/artemis/tree/develop).

## Usage

```nix
{
  description = "artemis execution environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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

in your `flake.nix`, then run

```shell
nix develop
```
