# Nix flake package for artemis

This is a flake for the [artemis](https://github.com/artemis-dev/artemis/tree/main).

## Usage

```nix
{
  description = "ARTEMIS workdir environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    artemis-flake = {
      url = "github:FumiHubCNS/artemis-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    artemis-flake,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        runtimePackages =
          artemis-flake.lib.${system}.runtimePackages;

        runtimeShellHook =
          artemis-flake.lib.${system}.runtimeShellHook;

      in
      {
        devShells.default = pkgs.mkShell {
          name = "training";

          packages = runtimePackages;

          shellHook = ''
            ${runtimeShellHook}

            # Let ROOT/cling resolve headers referenced by ARTEMIS PCM files.
            artemisIncludePath="$(artemis-config --incdir | tr ' ' ':')"
            export ROOT_INCLUDE_PATH="$artemisIncludePath''${ROOT_INCLUDE_PATH:+:$ROOT_INCLUDE_PATH}"

            echo
            echo "ARTEMIS workdir:"
            echo "  $PWD"
            echo
          '';
        };
      }
    );
}
```

in your `flake.nix`, then run

```shell
nix develop
```
