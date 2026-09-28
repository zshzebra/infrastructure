{ self, ... }:
{
  flake.nixosModules.core = {
    imports = [
      self.nixosModules.fish
      self.nixosModules.helix
      self.nixosModules.yazi
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    time.timeZone = "Australia/Sydney";
    i18n.defaultLocale = "en_AU.UTF-8";
    services.openssh.enable = true;
    networking.firewall.enable = true;
  };
}
