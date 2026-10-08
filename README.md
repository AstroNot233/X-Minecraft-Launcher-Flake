<p align="center">
  <a href="https://xmcl.app" target="_blank">
    <img alt="Logo" width="100" src="https://github.com/Voxelum/x-minecraft-launcher/blob/master/xmcl-electron-app/icons/dark@256x256.png">
  </a>
</p>

---

## Usage

### Trial with nix run

```sh
nix run github:AstroNot233/X-Minecraft-Launcher-Flake
```

### Install to user profile
```sh
# Install
nix profile add github:AstroNot233/X-Minecraft-Launcher-Flake
# Uninstall
nix profile remove X-Minecraft-Launcher-Flake
```

### Sustain with home-manager
```nix
# flake.nix
inputs = {
  # ...
  xmcl = {
    url = "github:AstroNot233/X-Minecraft-Launcher-Flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ...
};
```
```nix
# home.nix
imports = [
  inputs.xmcl.homeModules
];
programs.xmcl = {
  enable = true;
  launchEnv = {
    WEBKIT_DISABLE_DMABUF_RENDERER = 1;
    CUSTOMIZED_LAUNCH_ENV = "int / string";
  };
  launchArg = [
    "--electron_ozone_platform_hint=auto"
  ];
  jres = [
    pkgs.jdk8
    pkgs.jdk11
    pkgs.jdk17
    pkgs.jdk21
    pkgs.jdk25
    pkgs.any_other_jdk
  ];
};
```
