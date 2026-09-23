{
  stdenv,
  lib,
  cmake,
  pkg-config,
  root,
  yaml-cpp,
  src,
}:

stdenv.mkDerivation {
  pname = "getdecoder";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    root
    yaml-cpp
  ];

  patches = [
    ../patch/getdecoder-target-link-libraries.patch
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  postPatch = ''
    echo "===== GETDecoder patched target_link_libraries ====="
    grep -n 'target_link_libraries(GETDecoder' CMakeLists.txt
  '';

  postInstall = ''
    echo "===== GETDecoder install tree ====="
    find "$out" -maxdepth 4 -type f -print | sort
  '';
}
