{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "xmcl";
  version = "0.68.0";
  src = (
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
      gzs = {
        x86_64-linux = {
          url = "${base}/app-${version}-linux.asar.gz";
          hash = "sha256:1d9e5149698ff9df19596d8e10eccba9c834ba419f7c34dc383d1c0a144cc68c";
        };
        aarch64-linux = {
          url = "${base}/app-${version}-linux-arm64.asar.gz";
          hash = "sha256:cab25924976eeaa57c54a9785efd7ed953c8804a26b997e10080cb666cefe68c";
        };
      };
      sys = stdenv.hostPlatform.system;
      tar = gzs.${sys} or (throw "Unsupported system: ${sys}");
    in
      fetchurl tar
  );
  nativeBuildInputs = [
    gzip
  ];
  unpackPhase = ''
    runHook preUnpack
    mkdir -p "$out"
    gzip -dc "$src" > "$out/xmcl.asar"
    runHook postUnpack
  '';
}
