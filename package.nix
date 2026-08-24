{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "xmcl";
  version = "0.67.0";
  src = (
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${version}";
      gzs = {
        x86_64-linux = {
          url = "${base}/app-${version}-linux.asar.gz";
          hash = "sha256:529d0bdd9f0f39e7881969629b131b2681c01ab9333e320fd5cd2006689a3cb5";
        };
        aarch64-linux = {
          url = "${base}/app-${version}-linux-arm64.asar.gz";
          hash = "sha256:fe5464d403feedbcd92cb6a889e053afffbafcac986ba57da698aa4dd55a3086";
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
