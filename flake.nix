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

        artemis =
          pkgs.stdenv.mkDerivation
          {
            name = "artemis";
            version = "develop";
            src = pkgs.applyPatches {
              src = pkgs.fetchFromGitHub {
                owner = "artemis-dev";
                repo = "artemis";
                rev = "9f713420dcfaf75548a6bf94b60dc28d583ba952";
                hash = "sha256-TbDYtH0aMcJauIsQ2Y08z63QoYJ7XBFQxLUFT3rAbr0=";
              };
              patches = [./patch/thisartemis.sh.in.patch];
            };

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
              patchRcPathCsh
              patchRcPathFish
              patchRcPathPosix
            ];
            buildInputs = [
              pkgs.yaml-cpp
              pkgs-root.root
              pkgs.zlib
              pkgs.zlib.dev
            ];
            packages = [];

            cmakeFlags = [
              # "-DCMAKE_SKIP_INSTALL_RPATH=ON"
              "-DCMAKE_SKIP_BUILD_RPATH=ON"

              "-DCMAKE_INSTALL_BINDIR=bin"
              "-DCMAKE_INSTALL_INCLUDEDIR=include"
              "-DCMAKE_INSTALL_LIBDIR=lib"
            ];

            postInstall = ''
              # The main target of `thisroot.sh` is "bash-like shells",
              # but it also need to support Bash-less POSIX shell like dash,
              # as they are mentioned in `thisroot.sh`.
              # see: https://github.com/NixOS/nixpkgs/blob/852ff1d9e153d8875a83602e03fdef8a63f0ecf8/pkgs/by-name/ro/root/package.nix#L205C1-L207C46

              patchRcPathPosix "$out/bin/thisartemis.sh" "${
                pkgs.lib.makeBinPath [
                  pkgs.coreutils # uname, dirname, printf
                  pkgs.gnused # sed
                ]
              }"
              echo 'export CPATH=${pkgs.zlib.dev}/include:''${CPATH-}' >> "$out/bin/thisartemis.sh"
              echo 'export LD_LIBRARY_PATH=${pkgs.zlib}/lib:''${LD_LIBRARY_PATH-}' >> "$out/bin/thisartemis.sh"

              patchRcPathCsh "$out/bin/thisartemis.csh" "${
                pkgs.lib.makeBinPath [
                  pkgs.coreutils # dirname
                  pkgs.gnused # sed
                ]
              }"
              echo 'setenv CPATH ${pkgs.zlib.dev}/include:$CPATH' >> "$out/bin/thisartemis.csh"
              echo 'setenv LD_LIBRARY_PATH ${pkgs.zlib}/lib:$LD_LIBRARY_PATH' >> "$out/bin/thisartemis.csh"
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
