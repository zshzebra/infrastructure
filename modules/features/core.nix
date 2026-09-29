{
  flake.nixosModules.core = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    time.timeZone = "Australia/Sydney";
    i18n.defaultLocale = "en_AU.UTF-8";

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };
    networking.firewall.enable = true;

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJmshD4Go+e+SL5Tv5p57BcMLxyg6UhwgC0zIN3hWGG zshzebra@host"
    ];
  };
}
