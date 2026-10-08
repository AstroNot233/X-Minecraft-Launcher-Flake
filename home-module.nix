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
    with config.programs.xmcl;
    mkIf enable {
      home.packages = [ (pkgs.callPackage ./package.nix { inherit launchEnv launchArg; }) ];
      xdg.desktopEntries.xmcl = {
        categories = [ "Game" ];
        exec = "xmcl";
        icon = ./logo.png;
        name = "X Minecraft Launcher";
        terminal = false;
        type = "Application";
      };
      xdg.configFile."xmcl/java.json" = mkIf (jres != [ ]) {
        text = builtins.toJSON {
          all = builtins.map (jre: rec {
            path = "${jre}/bin/java";
            version = lib.getVersion jre;
            majorVersion =
              with lib;
              with versions;
              toInt ((if (toInt (major version) == 1) then minor else major) version);
          }) jres;
        };
      };
    };
}
