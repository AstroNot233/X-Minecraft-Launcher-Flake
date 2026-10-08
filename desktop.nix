{
  makeDesktopItem,
  ...
}:
makeDesktopItem {
  categories = [ "Game" ];
  desktopName = "X Minecraft Launcher";
  exec = "xmcl";
  icon = ./logo.png;
  name = "X Minecraft Launcher";
  startupWMClass = "X Minecraft Launcher";
  terminal = false;
  type = "Application";
}
