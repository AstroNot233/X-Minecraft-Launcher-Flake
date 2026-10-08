{
  buildFHSEnv,
  callPackage,
  lib,
  channel ? "release",
  launchEnv ? { },
  launchArg ? [ ],
  ...
}:
let
  xmcl = callPackage ./xmcl.nix { inherit channel; };
in
buildFHSEnv {
  # The release keeps the plain name; a preview is installed next to it.
  name = if channel == "release" then "xmcl" else "xmcl-${channel}";
  targetPkgs =
    pkgs: with pkgs; [
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
      ## misc
      wayland
      udev # oshi
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
    electron "${xmcl}/xmcl.asar" ${lib.escapeShellArgs launchArg}
  '';
}
