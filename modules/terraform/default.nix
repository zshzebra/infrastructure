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

  perSystem =
    { pkgs, self', ... }:
    let
      sopsProvider = pkgs.terraform-providers.mkProvider {
        owner = "elioetibr";
        repo = "terraform-provider-sops";
        rev = "v0.0.1";
        hash = "sha256-e+A/1OqdffkaJwlJp2apFkbxU9tI8ZzH5IBrbSxc4pA=";
        vendorHash = "sha256-7FyM3ah/2VRvvA7RVHVfUk2YNf1pfJeqiyxN/vrwcPw=";
        homepage = "https://github.com/elioetibr/terraform-provider-sops";
        provider-source-address = "registry.terraform.io/elioetibr/sops";
      };
    in
    {
      terranix.terranixConfigurations.infra = {
        terraformWrapper = {
          package = pkgs.opentofu.withPlugins (p: [
            p.hetznercloud_hcloud
            p.linode_linode
            p.cloudflare_cloudflare
            p.tailscale_tailscale
            p.hashicorp_random
            p.hashicorp_null
            p.hashicorp_external
            p.clementblaise_age
            sopsProvider
          ]);
          extraRuntimeInputs = [
            pkgs.jq
            pkgs.openssh
          ];
        };
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
