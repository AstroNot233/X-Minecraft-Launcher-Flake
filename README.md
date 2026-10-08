<p align="center">
  <img alt="Logo" width="100" src="./logo.png">
</p>

# X-Minecraft-Launcher-Flake

自动跟随上游发布的 [X Minecraft Launcher](https://xmcl.app) Nix flake，分 `release` 与 `preview` 两个渠道：
分别跟随上游最新正式版与最新预发布版。版本与各平台 source hash 由
[update 工作流](./.github/workflows/update.yml) 刷新，每次更新以与上游同名的 `v<version>` 打 tag。

A Nix flake for [X Minecraft Launcher](https://xmcl.app) that follows upstream releases, in two channels:
`release` (newest upstream release) and `preview` (newest prerelease). The
[update workflow](./.github/workflows/update.yml) refreshes their versions and per-platform source hashes,
tagging every bump as `v<version>`.

[![update](https://github.com/AstroNot233/X-Minecraft-Launcher-Flake/actions/workflows/update.yml/badge.svg)](https://github.com/AstroNot233/X-Minecraft-Launcher-Flake/actions/workflows/update.yml)

<!-- BEGIN PACKAGED -->

| Channel | Ref | `x86_64-linux` | `aarch64-linux` | Updated |
| --- | --- | :---: | :---: | --- |
| `release` | [`v0.71.0`](https://github.com/Voxelum/x-minecraft-launcher/releases/tag/v0.71.0) | ✅ [`fq8uYmsj…`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.71.0/app-0.71.0-linux.asar.gz) | ✅ [`4kiOOLey…`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.71.0/app-0.71.0-linux-arm64.asar.gz) | 2026-10-08 |
| `preview` | — | — | — | — |

<!-- END PACKAGED -->

| 图例 Legend | 描述 Description |
|:---:|:---|
| `✅` | hash 由 update 工作流从上游产物直接取得 · hash taken from the upstream artifact by the update workflow |
| `—` | 上游当前没有该渠道的版本 · upstream has no such release right now |

## 用法 Usage

### 试跑 Trial with nix run

```sh
nix run github:AstroNot233/X-Minecraft-Launcher-Flake             # release → xmcl
nix run github:AstroNot233/X-Minecraft-Launcher-Flake#preview     # preview → xmcl-preview
```

### 装进 profile Install to user profile

```sh
# Install
nix profile add github:AstroNot233/X-Minecraft-Launcher-Flake
nix profile add github:AstroNot233/X-Minecraft-Launcher-Flake#preview
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
  channel = "release"; # "preview" installs xmcl-preview next to it
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
| `programs.xmcl.channel` | `"release"` or `"preview"` | `"release"` | Which upstream channel to install; a preview is installed as `xmcl-preview`. |
| `programs.xmcl.jres` | list of package | `[ ]` | JREs/JDKs to be written into the launcher's Java list. |
| `programs.xmcl.launchEnv` | attrs | `{ }` | Environment variables for the launcher. |
| `programs.xmcl.launchArg` | list of string | `[ ]` | Arguments passed to the launcher. |

## 输出 Outputs

| Output | Description |
| --- | --- |
| `packages.<system>.default` | Alias of `release`. |
| `packages.<system>.release` | The release launcher (`xmcl`), wrapped in an FHS environment with its desktop entry. |
| `packages.<system>.preview` | The preview launcher (`xmcl-preview`). |
| `packages.<system>.asar` | Unwrapped release archive; the update workflow builds it to verify a hash. |
| `packages.<system>.asar-preview` | Unwrapped preview archive. |
| `homeModules` | home-manager module (see Options). |

## 更新机制 How updates work

[`.github/workflows/update.yml`](./.github/workflows/update.yml) runs weekly (Monday 03:00 UTC) and on
`workflow_dispatch`. What to track lives in [`config.json`](./config.json) — the channels and the systems —
and the work itself in [`.github/scripts/`](./.github/scripts):

1. `resolve` reads the upstream releases API and picks the newest release for the `release` channel and the
   newest prerelease for `preview`, refusing anything that is not a plain version string. A failed API call
   keeps the pinned channels instead of dropping them.
2. `hash` runs once per system (`ubuntu-latest`, `ubuntu-24.04-arm`), pins each channel's version, builds its
   `asar`, and takes the hash nix asks for out of the `hash mismatch` report. A runner can only hash its own
   system: the other one reports `platform mismatch`. Each job hands its pairs over as an artifact.
3. `publish` applies the versions and hashes to `sources.json`, rebuilds every pinned channel to verify
   them, refreshes the table above, and commits `v<version>` together with the matching tags.

`nix build .#release` and `nix build .#preview` fail with a clear message while a channel is not pinned;
`preview` is `null` in `sources.json` whenever upstream has no prerelease. Nothing is committed when nothing
moved, and a rerun at the same version means upstream replaced an artifact, in which case the hash is
corrected and its tag follows.
