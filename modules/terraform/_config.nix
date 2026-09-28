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

  provider.sops = { };

  data.sops_file.secrets = {
    source_file = "../secrets/providers.yaml";
  };

  provider.hcloud = {
    token = "\${data.sops_file.secrets.data[\"hcloud_token\"]}";
  };

  provider.linode = {
    token = "\${data.sops_file.secrets.data[\"linode_token\"]}";
  };

  provider.cloudflare = {
    api_token = "\${data.sops_file.secrets.data[\"cloudflare_token\"]}";
  };

  resource.hcloud_server.main = {
    image = "rocky-10";
    name = "main";
    server_type = "cpx22";
    location = "sin";
    # ssh_keys = [ "TODO" ];
    public_net = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
  };

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
