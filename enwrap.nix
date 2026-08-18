{ pkgs, lib, launchEnv ? {}, launchArg ? [], ... }:
(
  let
    xmcl-asar = pkgs.callPackage ./package.nix {};
  in
    pkgs.buildFHSEnv {
      name = "xmcl";
      targetPkgs = pkgs: with pkgs; [
      # For XMCL
        electron
      # For Minecraft
        stdenv.cc.cc.lib
        ## native versions
        glfw3-minecraft
        openal
        ## openal
        alsa-lib
        libjack2
        libpulseaudio
        pipewire
        ## glfw
        libGL
        libx11
        libxcursor
        libxext
        libxrandr
        libxxf86vm
        wayland
        udev          # oshi
        vulkan-loader # VulkanMod's lwjglt
        flite
        gamemode
        libusb1
      ];
      profile = ''
        set -o allexport
        ${lib.toShellVars launchEnv}
        set +o allexport
      '';
      runScript = ''
        electron "${xmcl-asar}/xmcl.asar" ${lib.escapeShellArgs launchArg}
      '';
    }
)
