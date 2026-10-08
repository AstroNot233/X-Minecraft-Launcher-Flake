{
  makeDesktopItem,
  channel ? "release",
  ...
}:
let
  release = channel == "release";
in
makeDesktopItem {
  categories = [ "Game" ];
  # desktopName is the entry's Name, name is the file it lands in.
  desktopName = if release then "X Minecraft Launcher" else "X Minecraft Launcher (Preview)";
  exec = if release then "xmcl" else "xmcl-${channel}";
  icon = ./logo.png;
  name = if release then "X Minecraft Launcher" else "xmcl-${channel}";
  startupWMClass = "X Minecraft Launcher";
  terminal = false;
  type = "Application";
}
