{ inputs, ... }:
{
  flake.nixosModules.sops =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = ../../secrets/hosts + "/${config.networking.hostName}.yaml";
        age.keyFile = "/var/lib/sops-nix/key.txt";
        age.sshKeyPaths = [ ];
        gnupg.sshKeyPaths = [ ];
      };
    };
}
