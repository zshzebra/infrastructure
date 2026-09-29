{ inputs, ... }:
{
  imports = [ inputs.terranix.flakeModule ];

  perSystem = { pkgs, self', ... }: {
    terranix.terranixConfigurations.infra = {
      terraformWrapper.package = pkgs.opentofu;
      modules = [
        ./_config.nix
        { _module.args.tofuAge = self'.packages.tofu-age-encryption; }
      ];
    };
  };
}
