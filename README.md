<p align="center">
  <img alt="Logo" width="100" src="./logo.png">
</p>

# X-Minecraft-Launcher-Flake

自动跟随上游发布的 [X Minecraft Launcher](https://xmcl.app) Nix flake。版本与两个平台的 source hash 由
[update 工作流](./.github/workflows/update.yml) 刷新，每次更新以 `v<version>` 打 tag。

A Nix flake for [X Minecraft Launcher](https://xmcl.app) that follows upstream releases. The
[update workflow](./.github/workflows/update.yml) refreshes the version and both platform source hashes,
tagging every bump as `v<version>`.

[![update](https://github.com/AstroNot233/X-Minecraft-Launcher-Flake/actions/workflows/update.yml/badge.svg)](https://github.com/AstroNot233/X-Minecraft-Launcher-Flake/actions/workflows/update.yml)

<!-- BEGIN PACKAGED -->

**0.71.0** · [upstream release `v0.71.0`](https://github.com/Voxelum/x-minecraft-launcher/releases/tag/v0.71.0) · updated 2026-10-08

| System | Source hash | Artifact |
| --- | --- | --- |
| `x86_64-linux` | ✅ `sha256-fq8uYmsjJEM913b3/eoEFN0scj+4zfqsowN/zYcMfNM=` | [`app-0.71.0-linux.asar.gz`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.71.0/app-0.71.0-linux.asar.gz) |
| `aarch64-linux` | ✅ `sha256-4kiOOLey3WxlowoAfThbBhhvxHVt3F3CSxvqOSXWjBo=` | [`app-0.71.0-linux-arm64.asar.gz`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.71.0/app-0.71.0-linux-arm64.asar.gz) |

<!-- END PACKAGED -->

| 图例 Legend | 描述 Description |
|:---:|:---|
| `✅` | hash 由 update 工作流从上游产物直接取得 · hash taken from the upstream artifact by the update workflow |

## 用法 Usage

### 试跑 Trial with nix run

```sh
nix run github:AstroNot233/X-Minecraft-Launcher-Flake
```

### 装进 profile Install to user profile

```sh
# Install
nix profile add github:AstroNot233/X-Minecraft-Launcher-Flake
# Uninstall
nix profile remove X-Minecraft-Launcher-Flake
```

### home-manager

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

### 固定版本 Pin a version

Tag 名与上游一致（`v<version>`），因此可以直接锁到某个版本：

```nix
inputs.xmcl.url = "github:AstroNot233/X-Minecraft-Launcher-Flake?ref=v0.71.0";
```

## 选项 Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `programs.xmcl.enable` | bool | `false` | Install the launcher and its desktop entry. |
| `programs.xmcl.jres` | list of package | `[ ]` | JREs/JDKs to be written into the launcher's Java list. |
| `programs.xmcl.launchEnv` | attrs | `{ }` | Environment variables for the launcher. |
| `programs.xmcl.launchArg` | list of string | `[ ]` | Arguments passed to the launcher. |

## 输出 Outputs

| Output | Description |
| --- | --- |
| `packages.<system>.default` | Launcher wrapped in an FHS environment, plus its desktop entry. |
| `packages.<system>.asar` | Unwrapped app archive; the update workflow builds it to verify a hash. |
| `homeModules` | home-manager module (see Options). |

## 更新机制 How updates work

[`.github/workflows/update.yml`](./.github/workflows/update.yml) runs weekly (Monday 03:00 UTC) and on
`workflow_dispatch`:

1. `version` resolves the latest upstream release from the electron-builder manifest the launcher itself
   updates with (`releases/latest/download/latest-linux.yml`), and refuses anything but a plain version
   string.
2. `hash` runs once per platform — `ubuntu-latest` and `ubuntu-24.04-arm` — pins the new version, builds
   `.#asar`, and takes the hash nix asks for out of the resulting `hash mismatch` report. A platform
   cannot be hashed from the other one's runner: it only reports `platform mismatch`.
3. `push` applies the version and both hashes, rebuilds `.#asar` to verify them, refreshes the table above,
   and commits `v<version>` together with the matching tag.

Nothing is committed when upstream has not moved; a rerun at the same version means upstream replaced an
artifact, in which case the hash is corrected and the tag follows it.
