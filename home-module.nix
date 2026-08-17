{ self }: { config, lib, pkgs, ... }:
(
  let
    inherit (lib) mkEnableOption mkOption mkIf;
  in
    {
      options.programs.xmcl = {
        enable = mkEnableOption "X Minecraft Launcher";
        package = mkOption {
          type = with lib.types; package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.default
            .override { inherit (config.programs.xmcl) launchEnv launchArg; };
          description = "The package of XMCL.";
          example = "mypkgs.xmcl";
        };
        jres = mkOption {
          type = with lib.types; listOf package;
          default = [];
          description = ''
            A list of packages of JREs/JDKs to be written into the Java list.
          '';
          example = [ pkgs.jre8 ];
        };
        launchEnv = mkOption {
          type = with lib.types; attrsOf anything;
          default = {};
          description = ''
            Environment variables or flags to be passed to XMCL.
          '';
          example = {
            WEBKIT_DISABLE_DMABUF_RENDERER = 1;
          };
        };
        launchArg = mkOption {
          type = with lib.types; listOf string;
          default = [];
          description = ''
            Launch options to be passed to XMCL.
          '';
          example = [
            "--electron_ozone_platform_hint=auto"
          ];
        };
      };
  
      config = with config.programs; mkIf xmcl.enable {
        home.packages = [ xmcl.package ];
        xdg.desktopEntries.xmcl = {
          categories = [ "Game" ];
          exec = "xmcl";
          icon = fetchurl {
            url = "https://raw.githubusercontent.com/Voxelum/x-minecraft-launcher/master/xmcl-electron-app/icons/dark%40StoreLogo.png";
            hash = "sha256:0acf82939cb10d69fcda2c90feb98048059d54fcde31f6b55740852cc66143b7";
          };
          name = "X Minecraft Launcher";
          terminal = false;
          type = "Application";
        };
        xdg.configFile."xmcl/java.json" = mkIf (xmcl.jres != []) {
          text = builtins.toJSON {
            all = builtins.map (jre: rec {
              path = "${jre}/bin/java";
              version = lib.getVersion jre;
              majorVersion = with lib; with versions; toInt ((if (toInt (major version) == 1) then minor else major) version);
            }) xmcl.jres;
          };
        };
      };
    }
)
