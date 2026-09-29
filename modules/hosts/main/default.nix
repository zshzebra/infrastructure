{ self, ... }:
{
  hosts.main = {
    hetzner = {
      type = "cpx22";
      location = "sin";
    };

    modules = [
      ./_disko.nix
      self.nixosModules.vikunja
      { system.stateVersion = "26.05"; }
    ];
  };
}
