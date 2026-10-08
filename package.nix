{
  callPackage,
  lib,
  symlinkJoin,
  channel ? "release",
  launchEnv ? { },
  launchArg ? [ ],
  ...
}:
let
  enwrap = callPackage ./enwrap.nix { inherit channel launchEnv launchArg; };
  desktop = callPackage ./desktop.nix { inherit channel; };
in
symlinkJoin {
  name = if channel == "release" then "x-minecraft-launcher" else "x-minecraft-launcher-${channel}";
  paths = [
    enwrap
    desktop
  ];
  meta = {
    description = "X Minecraft Launcher (${channel} channel)";
    homepage = "https://xmcl.app";
    license = lib.licenses.mit;
    # What `nix run` executes; the wrapper is named after the channel.
    mainProgram = if channel == "release" then "xmcl" else "xmcl-${channel}";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
