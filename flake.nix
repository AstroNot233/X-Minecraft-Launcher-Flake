{
  description = "An Open Source Minecraft Launcher with Modern UX.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  outputs = inputs: {
    packages = builtins.mapAttrs (
      system: pkgs:
      let
        sources = builtins.fromJSON (builtins.readFile ./sources.json);
      in
      rec {
        default = release;
        release = pkgs.callPackage ./package.nix { };
        # Unwrapped app archive, exposed so the update workflow can verify a new
        # source hash without building the FHS environment.
        asar = pkgs.callPackage ./xmcl.nix { };
      }
      # The upstream prerelease, installed as xmcl-preview next to the release.
      # Only while upstream has one: otherwise a plain `nix flake check` would
      # fail on an output that cannot be built.
      // pkgs.lib.optionalAttrs (sources.preview != null) {
        preview = pkgs.callPackage ./package.nix { channel = "preview"; };
        asar-preview = pkgs.callPackage ./xmcl.nix { channel = "preview"; };
      }
    ) inputs.nixpkgs.legacyPackages;
    homeModules = import ./home-module.nix inputs;
  };
}
