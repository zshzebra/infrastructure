{
  flake.nixosModules.tailscale =
    { config, ... }:
    {
      sops.secrets.tailscale_auth_key = { };

      services.tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
}
