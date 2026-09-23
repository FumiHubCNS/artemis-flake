{
  description = "Full ARTEMIS environment for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    artemisSrc = {
      url = "github:artemis-dev/artemis/master";
      flake = false;
    };

    getdecoderSrc = {
      url = "github:oedo-sharaq/GETDecoder";
      flake = false;
    };

    nestdaq = {
      url = "github:FumiHubCNS/nestdaq-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    userImpl = {
      url = "github:FumiHubCNS/nestdaq-user-impl-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    artemisSrc,
    getdecoderSrc,
    nestdaq,
    userImpl,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # --------------------------------------------------
        # Dependencies
        # --------------------------------------------------

        # Do not override ROOT.
        # Keep the nixpkgs derivation so the binary cache can be reused.
        root = pkgs.root;

        yaml-cpp = pkgs.yaml-cpp;
        openmpi = pkgs.openmpi;

        zeromq = pkgs.zeromq;
        hiredis = pkgs.hiredis;
        redis-plus-plus = pkgs.redis-plus-plus;

        # --------------------------------------------------
        # GETDecoder
        # --------------------------------------------------

        getdecoder =
          pkgs.callPackage ./pkgs/getdecoder.nix {
            src = getdecoderSrc;
            inherit root;
          };

        # --------------------------------------------------
        # ARTEMIS
        # --------------------------------------------------

        artemis =
          pkgs.callPackage ./pkgs/artemis.nix {
            src = artemisSrc;

            inherit
              root
              yaml-cpp
              openmpi
              zeromq
              hiredis
              redis-plus-plus
              getdecoder
              ;
          };

      in
      {
        packages = {
          inherit
            artemis
            getdecoder
            ;

          default = artemis;
        };

        devShells.default = pkgs.mkShell {
          name = "artemis-full-env";

          # Do not use inputsFrom here.
          # It can pull build-time setup hooks from ARTEMIS dependencies.
          # inputsFrom = [ artemis ];

          packages = [
            artemis
            getdecoder

            # Do not add root directly here.
            # ROOT is already used to build ARTEMIS/GETDecoder, and adding it
            # directly to mkShell makes its setup-hook run automatically.
            # root

            yaml-cpp
            openmpi
            zeromq
            hiredis
            redis-plus-plus

            pkgs.cmake
            pkgs.pkg-config
            pkgs.git
          ];

          shellHook = ''
            # ROOT itself is not added as a direct mkShell package, so its
            # nix-support/setup-hook is not intentionally activated here.
            #
            # thisroot.sh can still be sourced explicitly when testing ARTEMIS.
            source ${root}/bin/thisroot.sh
            source ${artemis}/bin/thisartemis.sh

	    # GETDecoder for ROOT/cling
	    export ROOT_INCLUDE_PATH="${getdecoder}:${getdecoder}/include''${ROOT_INCLUDE_PATH:+:$ROOT_INCLUDE_PATH}"
	    export LD_LIBRARY_PATH="${getdecoder}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

            echo
            echo "======================================"
            echo " ARTEMIS full development environment "
            echo "======================================"

            echo
            echo "ARTEMIS:"
            echo "  ${artemis}"

            echo
            echo "GETDecoder:"
            echo "  ${getdecoder}"

            echo
            echo "ROOT:"
            root-config --version || true

            echo
            echo "MPI:"
            mpirun --version | head -n 1 || true

            echo
            echo "ZeroMQ:"
            pkg-config --modversion libzmq || true

            echo
            echo "hiredis:"
            pkg-config --modversion hiredis || true

            echo
            echo "yaml-cpp:"
            pkg-config --modversion yaml-cpp || true

            echo
          '';
        };
      }
    );
}
