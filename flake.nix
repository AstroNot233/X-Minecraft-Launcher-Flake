{
  description = "An Open Source Minecraft Launcher with Modern UX.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: rec {
      default = release;
      release = pkgs.callPackage ./package.nix { };
      # The upstream prerelease, installed as xmcl-preview next to the release.
      preview = pkgs.callPackage ./package.nix { channel = "preview"; };
      # Unwrapped app archives, exposed so the update workflow can verify a new
      # source hash without building the FHS environment.
      asar = pkgs.callPackage ./xmcl.nix { };
      asar-preview = pkgs.callPackage ./xmcl.nix { channel = "preview"; };
    }) inputs.nixpkgs.legacyPackages;
    homeModules = import ./home-module.nix inputs;
  };
}
