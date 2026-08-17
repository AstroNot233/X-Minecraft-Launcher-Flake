{
  description = ''An Open Source Minecraft Launcher with Modern UX.'';
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { self, nixpkgs, ... }: (
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);
    in
      {
        packages = forAllSystems (system:
          { default = nixpkgs.legacyPackages.${system}.callPackage ./enwrap.nix {}; }
        );
        homeModules = import ./home-module.nix { inherit self; };
      }
  );
}
