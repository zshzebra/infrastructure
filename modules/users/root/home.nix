{ self, ... }:
{
  flake.homeModules.root = {
    imports = [
      self.homeModules.fish
      self.homeModules.helix
    ];
    home.stateVersion = "26.05";
  };
}
