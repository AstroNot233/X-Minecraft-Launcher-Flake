{
  stdenv,
  fetchurl,
  gzip,
  channel ? "release",
  ...
}:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  pinned =
    let
      entry = sources.${channel} or null;
    in
    if entry == null then
      throw "xmcl: no ${channel} release is pinned in sources.json"
    else
      entry;
in
stdenv.mkDerivation {
  pname = "xmcl-asar";
  version = pinned.version;
  src =
    let
      base = "https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${pinned.version}";
      artifacts = {
        x86_64-linux = "linux";
        aarch64-linux = "linux-arm64";
      };
      system = stdenv.hostPlatform.system;
      suffix = artifacts.${system} or (throw "Unsupported system: ${system}");
    in
    fetchurl {
      url = "${base}/app-${pinned.version}-${suffix}.asar.gz";
      hash = pinned.hash.${system} or (throw "No ${channel} hash for ${system}");
    };
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
