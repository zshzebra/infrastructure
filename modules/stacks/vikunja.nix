{
  flake.nixosModules.vikunja = {
    stacks.vikunja = {
      containers.db = {
        image = "docker.io/library/postgres:sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722";
        environment = {
          POSTGRES_USER = "vikunja";
          POSTGRES_DB = "vikunja";
        };
        environmentFiles = [
          # TODO: sops
        ];
        volumes.data.path = "/var/lib/postgresql/data";
      };

      containers.app = {
        image = "docker.io/vikunja/vikunja:sha256:417ada6f94e81f0267aa2f007d0a811fc82d38dd2aa58351e3ea520ca01c2ea5";
        environment = {
          VIKUNJA_DATABASE_TYPE = "postgres";
          VIKUNJA_DATABASE_HOST = "vikunja-db";
          VIKUNJA_DATABASE_USER = "vikunja";
          VIKUNJA_DATABASE_DATABASE = "vikunja";
        };
        environmentFiles = [
          # TODO: sops
        ];
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
