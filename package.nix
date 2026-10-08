{
  callPackage,
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

  };
}
