{
  flake.nixosModules.vikunja = { config, ... }: {
    sops.secrets.vikunja_db_password = { };
    sops.secrets.vikunja_jwt_secret = { };

    sops.templates."vikunja-db.env" = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder.vikunja_db_password}
      '';
      restartUnits = [ "podman-vikunja-db.service" ];
    };
    sops.templates."vikunja-app.env" = {
      content = ''
        VIKUNJA_DATABASE_PASSWORD=${config.sops.placeholder.vikunja_db_password}
        VIKUNJA_SERVICE_JWTSECRET=${config.sops.placeholder.vikunja_jwt_secret}
      '';
      restartUnits = [ "podman-vikunja-app.service" ];
    };

    stacks.vikunja = {
      containers.db = {
        image = "docker.io/library/postgres:18@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722";
        environment = {
          POSTGRES_USER = "vikunja";
          POSTGRES_DB = "vikunja";
        };
        environmentFiles = [ config.sops.templates."vikunja-db.env".path ];
        volumes.data.path = "/var/lib/postgresql";
      };

      containers.app = {
        image = "docker.io/vikunja/vikunja:latest@sha256:417ada6f94e81f0267aa2f007d0a811fc82d38dd2aa58351e3ea520ca01c2ea5";
        environment = {
          VIKUNJA_DATABASE_TYPE = "postgres";
          VIKUNJA_DATABASE_HOST = "vikunja-db";
          VIKUNJA_DATABASE_USER = "vikunja";
          VIKUNJA_DATABASE_DATABASE = "vikunja";
        };
        environmentFiles = [ config.sops.templates."vikunja-app.env".path ];
        volumes.files.path = "/app/vikunja/files";
        dependsOn = [ "db" ];
      };

      expose.tasks = {
        container = "app";
        port = 3456;
        hostPort = 3456;
      };
    };
  };
}
