{ self, inputs, ... }:
{
  flake.nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.core
      self.nixosModules.tailscale
      self.nixosModules.sops
      self.nixosModules.vpsConfiguration
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
