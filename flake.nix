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

        # --------------------------------------------------
        # Shared runtime environment
        #
        # This is used by:
        #   - artemis-flake devShell
        #   - external workdir flakes
        # --------------------------------------------------

        runtimePackages = [
          artemis
          getdecoder

          yaml-cpp
          openmpi
          zeromq
          hiredis
          redis-plus-plus

          pkgs.cmake
          pkgs.pkg-config
          pkgs.git
        ];

        runtimeShellHook = ''
          # ------------------------------------------------
          # ROOT / ARTEMIS
          # ------------------------------------------------

          source ${root}/bin/thisroot.sh
          source ${artemis}/bin/thisartemis.sh

          # ------------------------------------------------
          # GETDecoder for ROOT/cling
          #
          # Some ROOT dictionaries contain paths such as:
          #
          #   GETHeaderBase.hh
          #   include/GETTopologyFrame.hh
          #
          # Therefore both the package root and include/
          # directory are added.
          # ------------------------------------------------

          export ROOT_INCLUDE_PATH="${getdecoder}:${getdecoder}/include''${ROOT_INCLUDE_PATH:+:$ROOT_INCLUDE_PATH}"

          # ------------------------------------------------
          # Runtime shared libraries
          #
          # ARTEMIS:
          #   libartshare.so
          #   libCAT.so
          #   libcatcore.so
          #   ...
          #
          # GETDecoder:
          #   libGETDecoder.so
          # ------------------------------------------------

          export LD_LIBRARY_PATH="${artemis}/lib:${getdecoder}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        '';

      in
      {
        # --------------------------------------------------
        # Packages
        # --------------------------------------------------

        packages = {
          inherit
            artemis
            getdecoder
            ;

          default = artemis;
        };

        # --------------------------------------------------
        # Reusable runtime environment
        #
        # External flakes can access:
        #
        #   artemis-flake.lib.${system}.runtimePackages
        #   artemis-flake.lib.${system}.runtimeShellHook
        # --------------------------------------------------

        lib = {
          inherit
            runtimePackages
            runtimeShellHook
            ;
        };

        # --------------------------------------------------
        # Development shell
        # --------------------------------------------------

        devShells.default = pkgs.mkShell {
          name = "artemis-full-env";

          # Do not use:
          #
          #   inputsFrom = [ artemis ];
          #
          # ARTEMIS depends on ROOT, and ROOT's setup-hook can
          # execute thisroot automatically during mkShell
          # construction.
          #
          # Instead, dependencies are explicitly listed here
          # and thisroot.sh is sourced manually below.

          packages = runtimePackages;

          shellHook = ''
            ${runtimeShellHook}

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
            echo "redis-plus-plus:"
            pkg-config --modversion redis++ 2>/dev/null || true

            echo
            echo "yaml-cpp:"
            pkg-config --modversion yaml-cpp || true

            echo
          '';
        };
      }
    );
}
