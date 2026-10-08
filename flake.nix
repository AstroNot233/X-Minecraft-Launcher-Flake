{
  description = "An Open Source Minecraft Launcher with Modern UX.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      default = pkgs.callPackage ./package.nix { };
      # Unwrapped app archive, exposed so .github/workflows/update.yml can
      # verify a new source hash without building the FHS environment.
      asar = pkgs.callPackage ./xmcl.nix { };
    }) inputs.nixpkgs.legacyPackages;
    homeModules = import ./home-module.nix inputs;
  };
}
