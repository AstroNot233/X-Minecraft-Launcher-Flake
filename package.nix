{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "xmcl";
  version = "0.66.2";
  src = (
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
      gzs = {
        x86_64-linux = {
          url = "${base}/app-${version}-linux.asar.gz";
          hash = "sha256:9b2f84dce18526f56a82649d6aba0dbb9811a9251b4c3c27cc677274f1dab046";
        };
        aarch64-linux = {
          url = "${base}/app-${version}-linux-arm64.asar.gz";
          hash = "sha256:534a9fa9a276e98214dea2ad64217445e7b7f3351ce08d2b9f5313472041a2e7";
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
