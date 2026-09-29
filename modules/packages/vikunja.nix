{
  perSystem =
    { pkgs, ... }:
    let
      rev = "d65e52ea01c68e01812d1859809b1d9aee05e9ef";

      vikunja = pkgs.vikunja.overrideAttrs (
        final: prev: {
          version = "2.6.0-${builtins.substring 0 7 rev}";
          src = pkgs.fetchFromGitHub {
            owner = "mds08011";
            repo = "vikunja";
            inherit rev;
            hash = "sha256-J8MnGBARVEp9SXryETVL+/HZ5ldsl/S2rLJLhPgyDGU=";
          };
          vendorHash = "sha256-JuGo6mCcIf1P9DKA6msFaRVEe7lrYryOWeO5xaV2Tjk=";

          veans = prev.veans.overrideAttrs {
            vendorHash = "sha256-cCRPfJDZXIlufMg3SkqtI7Hb5Dphu2Eofxuls3eSS+Q=";
          };

          doCheck = false;

          frontend = prev.frontend.overrideAttrs (fprev: {
            pnpmDeps = fprev.pnpmDeps.overrideAttrs {
              outputHash = "sha256-Urm9LpO7piZ7rmUL2sRnYxej3rgeMFamwWaNd863JP4=";
            };
          });
        }
      );
    in
    {
      packages.vikunja = vikunja;

      packages.vikunja-image = pkgs.dockerTools.streamLayeredImage {
        name = "vikunja";
        tag = vikunja.version;
        contents = [
          pkgs.cacert
          pkgs.tzdata
        ];
        extraCommands = "mkdir -p app/vikunja/files";
        config = {
          Entrypoint = [ "${vikunja}/bin/vikunja" ];
          WorkingDir = "/app/vikunja";
          User = "1000:1000";
          Env = [ "VIKUNJA_SERVICE_ROOTPATH=/app/vikunja" ];
          ExposedPorts."3456/tcp" = { };
        };
      };
    };
}
