{
  lib,
  config,
  inputs,
  self,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.hosts = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          system = mkOption {
            type = types.str;
            default = "x86_64-linux";
          };
          hetzner.type = mkOption {
            type = types.str;
          };
          hetzner.location = mkOption {
            type = types.str;
          };
          modules = mkOption {
            type = types.listOf types.deferredModule;
            default = [ ];
          };
        };
      }
    );
    default = { };
  };

  config.flake.nixosConfigurations = lib.mapAttrs (
    name: host:
    inputs.nixpkgs.lib.nixosSystem {
      modules = host.modules ++ [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.core
        self.nixosModules.stacks
        {
          networking.hostName = name;
          nixpkgs.hostPlatform = host.system;
        }
      ];
    }
  ) config.hosts;
}
