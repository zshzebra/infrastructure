{ inputs, ... }:
{
  imports = [ inputs.terranix.flakeModule ];

  perSystem = { pkgs, ... }: {
    terranix.terranixConfigurations.infra = {
      terraformWrapper.package = pkgs.opentofu;
      modules = [ ./_config.nix ];
    };
  };
}
