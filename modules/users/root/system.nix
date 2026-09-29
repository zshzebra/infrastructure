{ self, ... }:
{
  flake.nixosModules.userRoot = {
    home-manager.users.root = self.homeModules.root;
  };
}
