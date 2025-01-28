{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        artemis = pkgs.stdenv.mkDerivation
          {
            name = "artemis";
            version = "develop";
            src = pkgs.fetchFromGitHub {
              owner = "artemis-dev";
              repo = "artemis";
              rev = "87ff6ff183fe1e5b48431d73e94d9041481f0f23";
              hash = "sha256-mc4wXwZPjRXPGlnSEMmZnAnUAWpSBaHAvOhI4Pgvyss=";
            };

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
              patchRcPathCsh
              patchRcPathFish
              patchRcPathPosix
            ];
            buildInputs = with pkgs; [
              yaml-cpp
              root
              zlib
            ];

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
              patchRcPathCsh "$out/bin/thisartemis.csh" "${
                pkgs.lib.makeBinPath [
                  pkgs.coreutils # dirname
                  pkgs.gnused # sed
                ]
              }"
            '';

            meta = {
              homepage = "https://github.com/artemis-dev/artemis/tree/develop";
              mainProgram = "artemis";
              platforms = pkgs.lib.platforms.unix;
              # license = pkgs.lib.licenses.unlicense;
            };
          };

      in
      {
        packages = {
          inherit artemis;
          default = artemis;
        };
      }
    );
}





