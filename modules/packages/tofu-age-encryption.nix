{
  perSystem = { pkgs, ... }: {
    packages.tofu-age-encryption = pkgs.buildGoModule {
      pname = "tofu-age-encryption";
      version = "61d27b9d74b59cd06fa020efe8be8aae492f29fb";
      src = pkgs.fetchFromGitHub {
        owner = "josh";
        repo = "tofu-age-encryption";
        rev = "61d27b9d74b59cd06fa020efe8be8aae492f29fb";
        hash = "sha256-Xviu2tvwvxmsz2eAgFem8BGUe7d6PV0jhNY7t1KSkTo=";
      };
      vendorHash = "sha256-34PpsE2chrLxONGrR9YoSplPNN/uVuCxkUMrBZudmAc=";
      nativeCheckInputs = [
        pkgs.opentofu
        pkgs.jq
        pkgs.age
      ];
    };
  };
}
