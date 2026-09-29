{
  inputs,
  self,
  config,
  ...
}:
let
  hosts = config.hosts;
in
{
  imports = [ inputs.terranix.flakeModule ];

  perSystem = { pkgs, self', ... }: {
    terranix.terranixConfigurations.infra = {
      terraformWrapper.package = pkgs.opentofu;
      modules = [
        ./_config.nix
        {
          _module.args = {
            inherit hosts;
            nixosConfigurations = self.nixosConfigurations;
            tofuAge = self'.packages.tofu-age-encryption;
          };
        }
      ];
    };
  };
}
