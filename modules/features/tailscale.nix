{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      exposes = lib.concatMapAttrs (_: stack: stack.expose) config.stacks;
    in
    {
      sops.secrets.tailscale_auth_key = { };

      services.tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        serve = {
          enable = exposes != { };
          services = lib.mapAttrs (_: e: {
            endpoints."tcp:80" = "http://127.0.0.1:${toString e.hostPort}";
          }) exposes;
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
}
