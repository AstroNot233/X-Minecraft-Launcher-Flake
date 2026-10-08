{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "xmcl-asar";
  version = "0.71.0";
  src =
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
      gzs = {
        x86_64-linux = {
          url = "${base}/app-${version}-linux.asar.gz";
          hash = "sha256-fq8uYmsjJEM913b3/eoEFN0scj+4zfqsowN/zYcMfNM=";
        };
        aarch64-linux = {
          url = "${base}/app-${version}-linux-arm64.asar.gz";
          hash = "sha256-4kiOOLey3WxlowoAfThbBhhvxHVt3F3CSxvqOSXWjBo=";
        };
      };
      sys = stdenv.hostPlatform.system;
      tar = gzs.${sys} or (throw "Unsupported system: ${sys}");
    in
    fetchurl tar;
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
