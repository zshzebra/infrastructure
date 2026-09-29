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
  injectAgeKey = pkgs.writeShellScript "inject-age-key" ''
    umask 077
    mkdir -p var/lib/sops-nix
    printf '%s\n' "$SOPS_AGE_KEY" > var/lib/sops-nix/key.txt
  '';
  nixosAnywhere = "github.com/nix-community/nixos-anywhere//terraform";
in
{
  terraform.required_providers = {
    sops = {
      source = "elioetibr/sops";
    };
    hcloud = {
      source = "hetznercloud/hcloud";
    };
    linode = {
      source = "linode/linode";
    };
    cloudflare = {
      source = "cloudflare/cloudflare";
    };
    tailscale = {
      source = "tailscale/tailscale";
    };
    age = {
      source = "clementblaise/age";
    };
    random = {
      source = "hashicorp/random";
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

  provider.tailscale = {
    oauth_client_id = secret "tailscale_oauth_client_id";
    oauth_client_secret = secret "tailscale_oauth_client_secret";
  };

  resource.age_secret_key = lib.mapAttrs (_: _: { }) hosts;

  resource.tailscale_tailnet_key = lib.mapAttrs (_: _: {
    reusable = true;
    preauthorized = true;
    tags = [ "tag:server" ];
  }) hosts;

  resource.random_password.restic = {
    length = 48;
    special = false;
  };

  resource.random_password.vikunja_db = {
    length = 32;
    special = false;
  };
  resource.random_password.vikunja_jwt = {
    length = 64;
    special = false;
  };

  resource.sops_file = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "host_${name}" {
      path = "../secrets/hosts/${name}.yaml";
      input_type = "yaml";
      content_wo = "\${yamlencode({
      tailscale_auth_key   = tailscale_tailnet_key.${name}.key,
      vikunja_db_password = random_password.vikunja_db.result,
      vikunja_jwt_secret  = random_password.vikunja_jwt.result,
      restic_password   = random_password.restic.result,
      restic_access_key = linode_object_storage_key.backups.access_key,
      restic_secret_key = linode_object_storage_key.backups.secret_key,
      restic_repository = \"s3:https://\${linode_object_storage_bucket.backups.s3_endpoint}/\${linode_object_storage_bucket.backups.label}/${name}\",
    })}";
      content_wo_version = "\${join(\",\", [
      tailscale_tailnet_key.${name}.id,
      random_password.restic.id,
      linode_object_storage_key.backups.id,
      random_password.vikunja_db.id,
      random_password.vikunja_jwt.id,
    ])}";
      creation_rules.age_recipients = ageRecipients ++ [ "\${age_secret_key.${name}.public_key}" ];
    }
  ) hosts;

  module = lib.concatMapAttrs (name: _: {
    "build_${name}" = {
      source = "${nixosAnywhere}/nix-build";
      attribute = "..#nixosConfigurations.${name}.config.system.build.toplevel";
      depends_on = [ "sops_file.host_${name}" ];
    };
    "partitioner_${name}" = {
      source = "${nixosAnywhere}/nix-build";
      attribute = "..#nixosConfigurations.${name}.config.system.build.diskoScript";
    };
    "install_${name}" = {
      source = "${nixosAnywhere}/install";
      nixos_system = "\${module.build_${name}.result.out}";
      nixos_partitioner = "\${module.partitioner_${name}.result.out}";
      target_host = "\${hcloud_server.${name}.ipv4_address}";
      instance_id = "\${hcloud_server.${name}.id}";
      extra_files_script = "${injectAgeKey}";
      extra_environment = {
        SOPS_AGE_KEY = "\${age_secret_key.${name}.secret_key}";
      };
    };
    "deploy_${name}" = {
      source = "${nixosAnywhere}/nixos-rebuild";
      nixos_system = "\${module.build_${name}.result.out}";
      target_host = name; # MagicDNS
      depends_on = [ "module.install_${name}" ];
    };
  }) hosts;

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
