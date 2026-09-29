{
  flake.homeModules.fish = {
    programs.fish.enable = true;

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
