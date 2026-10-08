self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options.programs.xmcl = {
    enable = mkEnableOption "X Minecraft Launcher";
    channel = mkOption {
      type = with lib.types; enum [ "release" "preview" ];
      default = "release";
      description = ''
        Which upstream channel to install: the latest release, or the latest
        preview, which lands next to it as `xmcl-preview`.
      '';
      example = "preview";
    };
    jres = mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        A list of packages of JREs/JDKs to be written into the Java list.
      '';
      example = [ pkgs.jre8 ];
    };
    launchEnv = mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Environment variables or flags to be passed to XMCL.
      '';
      example = {
        WEBKIT_DISABLE_DMABUF_RENDERER = 1;
      };
    };
    launchArg = mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = ''
        Launch options to be passed to XMCL.
      '';
      example = [
        "--electron_ozone_platform_hint=auto"
      ];
    };
  };

  config =
    let
      cfg = config.programs.xmcl;
      release = cfg.channel == "release";
      bin = if release then "xmcl" else "xmcl-${cfg.channel}";
      label = if release then "X Minecraft Launcher" else "X Minecraft Launcher (Preview)";
    in
    mkIf cfg.enable {
      home.packages = [ (pkgs.callPackage ./package.nix { inherit (cfg) channel launchEnv launchArg; }) ];
      xdg.desktopEntries.${bin} = {
        categories = [ "Game" ];
        exec = bin;
        icon = ./logo.png;
        name = label;
        terminal = false;
        type = "Application";
      };
      xdg.configFile."xmcl/java.json" = mkIf (cfg.jres != [ ]) {
        text = builtins.toJSON {
          all = builtins.map (jre: rec {
            path = "${jre}/bin/java";
            version = lib.getVersion jre;
            majorVersion =
              with lib;
              with versions;
              toInt ((if (toInt (major version) == 1) then minor else major) version);
          }) cfg.jres;
        };
      };
    };
}
