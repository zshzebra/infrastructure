{
  flake.nixosModules.backups =
    { config, lib, ... }:
    let
      paths = lib.concatLists (
        lib.mapAttrsToList (
          _: stack:
          lib.concatLists (
            lib.mapAttrsToList (
              cName: c:
              lib.mapAttrsToList (vName: _: "${stack.dataDir}/${cName}/${vName}") (
                lib.filterAttrs (_: v: v.backup) c.volumes
              )
            ) stack.containers
          )
        ) config.stacks
      );

      units = lib.concatLists (
        lib.mapAttrsToList (
          sName: stack: lib.mapAttrsToList (cName: _: "podman-${sName}-${cName}.service") stack.containers
        ) config.stacks
      );
    in
    lib.mkIf (paths != [ ]) {
      sops.secrets.restic_password = { };
      sops.secrets.restic_repository = { };
      sops.secrets.restic_access_key = { };
      sops.secrets.restic_secret_key = { };
      sops.templates."restic.env".content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder.restic_access_key}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.restic_secret_key}
      '';

      services.restic.backups.stacks = {
        initialize = true;
        repositoryFile = config.sops.secrets.restic_repository.path;
        passwordFile = config.sops.secrets.restic_password.path;
        environmentFile = config.sops.templates."restic.env".path;
        inherit paths;
        backupPrepareCommand = "systemctl stop ${lib.concatStringsSep " " units}";
        backupCleanupCommand = "systemctl start ${lib.concatStringsSep " " units}";
        timerConfig = {
          OnCalendar = "03:00";
          Persistent = true;
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 12"
        ];
      };
    };
}
