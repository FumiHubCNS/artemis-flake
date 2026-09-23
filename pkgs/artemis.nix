{
  stdenv,
  lib,
  cmake,
  pkg-config,

  root,
  yaml-cpp,
  openmpi,
  zeromq,
  hiredis,
  redis-plus-plus,
  zlib,
  getdecoder,

  src,
}:

stdenv.mkDerivation {
  pname = "artemis";
  version = "main";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    root
    yaml-cpp
    openmpi
    zeromq
    hiredis
    redis-plus-plus
    zlib
    getdecoder
  ];

  patches = [
    ../patch/artemis-config.cmake.in.patch
    ../patch/thisartemis.sh.in.patch
    ../patch/artemis-yaml-tstring.patch
    ../patch/artemis-format-security.patch
    ../patch/artemis-format-security-streaming-v1.patch
  ];


  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  
    "-DBUILD_GET=ON"
    "-DWITH_GET_DECODER=${getdecoder}"
  
    "-DBUILD_WITH_REDIS=ON"
    "-DBUILD_WITH_ZMQ=ON"
  
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
    "-DCMAKE_INSTALL_RPATH=${lib.makeLibraryPath [
      root
      yaml-cpp
      openmpi
      zeromq
      hiredis
      redis-plus-plus
      getdecoder
      zlib
    ]}"
  ];

  postConfigure = ''
    echo "===== ARTEMIS configure ====="
    echo "ROOT        = ${root}"
    echo "yaml-cpp    = ${yaml-cpp}"
    echo "OpenMPI     = ${openmpi}"
    echo "ZeroMQ      = ${zeromq}"
    echo "hiredis     = ${hiredis}"
    echo "redis++     = ${redis-plus-plus}"
    echo "zlib        = ${zlib}"
    echo "GETDecoder  = ${getdecoder}"
  '';

  postInstall = ''
    echo "===== ARTEMIS install tree ====="
    find "$out" -maxdepth 4 -type f -print | sort
  '';
}
