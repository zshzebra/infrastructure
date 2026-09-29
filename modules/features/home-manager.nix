{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.nixosModules.homeManager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-bak";
  };
}
