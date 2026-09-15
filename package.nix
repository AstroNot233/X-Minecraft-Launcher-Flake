{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "xmcl";
  version = "0.70.0";
  src = (
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
      gzs = {
        x86_64-linux = {
          url = "${base}/app-${version}-linux.asar.gz";
          hash = "sha256:a63fd73ca81631a3f59ae4d274cee2583f32039145bae7fec186c2cf8497a81e";
        };
        aarch64-linux = {
          url = "${base}/app-${version}-linux-arm64.asar.gz";
          hash = "sha256:90bc8a1b5293549cfbd1e968379a49f4eeee198c5527e9adfc540aedf5bbcb98";
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
