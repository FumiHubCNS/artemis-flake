{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    root-pin.url = "github:NixOS/nixpkgs/f3fd821e8dab2b31bdafd91a1997cdeee2eae790";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    root-pin,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        pkgs-root = import root-pin {inherit system;};
        root = pkgs-root.root;

        artemis =
          pkgs.stdenv.mkDerivation
          {
            pname = "artemis";
            version = "2026-08-01";
            src = pkgs.applyPatches {
              src = pkgs.fetchFromGitHub {
                owner = "artemis-dev";
                repo = "artemis";
                rev = "9fb27c3e67634636ec8c2c40d378e3e2a7e5388e";
                hash = "sha256-81wXoImosafxikT2jllAJouUJOtIkKwno6q1vHzAbUw=";
              };
              patches = [
                ./patch/artemis-config.cmake.in.patch
                ./patch/cmake-linker-flags.patch
                ./patch/thisartemis.sh.in.patch
              ];
            };

            nativeBuildInputs = [
              pkgs.cmake
              pkgs.pkg-config
              pkgs.gnused
              pkgs.patchRcPathCsh
              pkgs.patchRcPathPosix
            ];
            buildInputs = [
              pkgs.yaml-cpp
              pkgs.zlib
              root
            ];

            # Artemis exposes CMake targets that link to both ROOT and yaml-cpp.
            # They must be present in projects that consume it.
            propagatedBuildInputs = [
              pkgs.yaml-cpp
              root
            ];

            strictDeps = true;

            cmakeFlags = [
              # "-DCMAKE_SKIP_INSTALL_RPATH=ON"
              "-DCMAKE_SKIP_BUILD_RPATH=ON"

              "-DCMAKE_INSTALL_BINDIR=bin"
              "-DCMAKE_INSTALL_INCLUDEDIR=include"
              "-DCMAKE_INSTALL_LIBDIR=lib"
            ];

            env.CPATH = "${pkgs.zlib.dev}/include";

            postInstall = ''
              patchRcPathPosix "$out/bin/thisartemis.sh" "${
                pkgs.lib.makeBinPath [
                  pkgs.coreutils # uname, dirname
                ]
              }"
              # Support `source thisartemis.sh` outside `nix develop` too.
              sed -i '1i. ${root}/bin/thisroot.sh' "$out/bin/thisartemis.sh"

              patchRcPathCsh "$out/bin/thisartemis.csh" "${
                pkgs.lib.makeBinPath [
                  pkgs.coreutils
                ]
              }"
              sed -i '1csource ${root}/bin/thisroot.csh' "$out/bin/thisartemis.csh"
            '';

            setupHook = ./setup-hook.sh;

            meta = {
              homepage = "https://artemis-dev.github.io";
              mainProgram = "artemis";
              platforms = pkgs.lib.platforms.unix;
              # license = pkgs.lib.licenses.unlicense;
            };
          };
      in {
        packages = {
          inherit artemis;
          default = artemis;
        };
      }
    );
}
