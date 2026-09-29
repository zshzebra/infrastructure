{
  flake.homeModules.helix = {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "catppuccin_mocha";
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
        };
      };
    };
  };
}
