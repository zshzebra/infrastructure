{ self, ... }:
{
  flake.nixosModules.userZshzebra = { pkgs, ... }: {
    users.users.zshzebra = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJmshD4Go+e+SL5Tv5p57BcMLxyg6UhwgC0zIN3hWGG zshzebra@host"
      ];
    };

    programs.fish.enable = true;
    home-manager.users.zshzebra = self.homeModules.zshzebra;
  };
}
