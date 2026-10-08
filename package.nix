{
  callPackage,
  symlinkJoin,
  launchEnv ? { },
  launchArg ? [ ],
  ...
}:
let
  enwrap = callPackage ./enwrap.nix { inherit launchEnv launchArg; };
  desktop = callPackage ./desktop.nix { };
in
symlinkJoin {
  name = "x-minecraft-launcher";
  paths = [
    enwrap
    desktop
  ];
  meta = {

  };
}
