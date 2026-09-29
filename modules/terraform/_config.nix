{
  pkgs,
  lib,
  hosts,
  tofuAge,
  ...
}:
let
  ageRecipients = [ "age1h2l56zaq0m344qgthuuqwqpmpq4xs3c7f5u2w4vchcvtlynmkq7s9kgcpq" ];
  tofuAgeBin = "${tofuAge}/bin/tofu-age-encryption";
  secret = key: "\${data.sops_file.secrets.data[\"${key}\"]}";
in
{
  terraform.required_providers = {
    sops = {
      source = "carlpett/sops";
      version = "~> 1.4";
    };
    hcloud = {
      source = "hetznercloud/hcloud";
      version = "~> 1.69";
    };
    linode = {
      source = "linode/linode";
      version = "~> 4.5";
    };
    cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5";
    };
  };

  terraform.encryption = {
    method.external.age = {
      encrypt_command = [
        tofuAgeBin
        "--encrypt"
        "--recipient"
        (lib.concatStringsSep "," ageRecipients)
      ];
      decrypt_command = [
        tofuAgeBin
        "--decrypt"
        "--identity"
        "cmd:${pkgs.coreutils}/bin/cat $HOME/.config/sops/age/keys.txt"
      ];
    };

    state = {
      method = "method.external.age";
      enforced = true;
    };
    plan = {
      method = "method.external.age";
      enforced = true;
    };
  };

  provider.sops = { };

  data.sops_file.secrets = {
    source_file = "../secrets/providers.yaml";
  };

  provider.hcloud = {
    token = secret "hcloud_token";
  };

  provider.linode = {
    token = secret "linode_token";
  };

  provider.cloudflare = {
    api_token = secret "cloudflare_token";
  };

  resource.hcloud_ssh_key.install = {
    name = "install";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINJmshD4Go+e+SL5Tv5p57BcMLxyg6UhwgC0zIN3hWGG zshzebra@host";

  };

  resource.hcloud_server = lib.mapAttrs (name: host: {
    inherit name;
    image = "debian-12";
    server_type = host.hetzner.type;
    location = host.hetzner.location;
    ssh_keys = [ "\${hcloud_ssh_key.install.id}" ];
    public_net = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
  }) hosts;

  resource.linode_object_storage_bucket.backups = {
    label = "zshzebra-docker-backups-test";
    region = "sg-sin-2";
  };

  resource.linode_object_storage_key.backups = {
    label = "$\{linode_object_storage_bucket.backups.label}-key";

    bucket_access = {
      bucket_name = "$\{linode_object_storage_bucket.backups.label}";
      region = "$\{linode_object_storage_bucket.backups.region}";
      permissions = "read_write";
    };
  };
}
