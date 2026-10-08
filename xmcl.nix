{
  stdenv,
  fetchurl,
  gzip,
  channel ? "release",
  ...
}:
let
  # config.json names the upstream repository and the asset suffix per system;
  # sources.json is what the update workflow pins.
  config = builtins.fromJSON (builtins.readFile ./config.json);
  sources = builtins.fromJSON (builtins.readFile ./sources.json);

  pinned =
    let
      entry = sources.${channel} or null;
    in
    if entry == null then
      throw "xmcl: no ${channel} release is pinned in sources.json"
    else
      entry;

  system = stdenv.hostPlatform.system;
  assets = builtins.listToAttrs (
    map (s: {
      name = s.name;
      value = s.asset;
    }) config.systems
  );
  suffix = assets.${system} or (throw "Unsupported system: ${system}");
  version = pinned.version;
in
stdenv.mkDerivation {
  pname = "xmcl-asar";
  version = version;
  src =
    let
      base = "${config.upstream_repo}/releases/download/v${version}";
    in
    fetchurl {
      url = "${base}/app-${version}-${suffix}.asar.gz";
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
