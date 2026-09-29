{
  flake.nixosModules.stacks =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;

      volumeType = types.submodule {
        options = {
          path = mkOption { type = types.str; };
          backup = mkOption {
            type = types.bool;
            default = true;
          };
        };
      };

      containerType = types.submodule {
        options = {
          image = mkOption { type = types.str; };
          environment = mkOption {
            type = types.attrsOf types.str;
            default = { };
          };
          environmentFiles = mkOption {
            type = types.listOf types.path;
            default = [ ];
          };
          volumes = mkOption {
            type = types.attrsOf volumeType;
            default = { };
          };
          dependsOn = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
        };
      };

      exposeType = types.submodule {
        options = {
          container = mkOption { type = types.str; };
          port = mkOption { type = types.port; };
          hostPort = mkOption { type = types.port; };
        };
      };

      stackType = types.submodule (
        { name, ... }: {
          options = {
            containers = mkOption {
              type = types.attrsOf containerType;
              default = { };
            };
            expose = mkOption {
              type = types.attrsOf exposeType;
              default = { };
            };
            dataDir = mkOption {
              type = types.str;
              default = "/var/lib/stacks/${name}";
            };
          };
        }
      );

      allContainers = lib.concatLists (
        lib.mapAttrsToList (
          stackName: stack:
          lib.mapAttrsToList (cName: c: {
            inherit
              stackName
              stack
              cName
              c
              ;
          }) stack.containers
        ) config.stacks
      );
    in
    {
      options.stacks = mkOption {
        type = types.attrsOf stackType;
        default = { };
      };

      config = {
        virtualisation.oci-containers.backend = "podman";

        virtualisation.oci-containers.containers = lib.listToAttrs (
          map (
            {
              stackName,
              stack,
              cName,
              c,
            }:
            lib.nameValuePair "${stackName}-${cName}" {
              inherit (c) image environment environmentFiles;
              networks = [ stackName ];
              dependsOn = map (d: "${stackName}-${d}") c.dependsOn;
              volumes = lib.mapAttrsToList (vName: v: "${stack.dataDir}/${cName}/${vName}:${v.path}") c.volumes;
              ports = lib.mapAttrsToList (_: e: "127.0.0.1:${toString e.hostPort}:${toString e.port}") (
                lib.filterAttrs (_: e: e.container == cName) stack.expose
              );
            }
          ) allContainers
        );

        systemd.services = lib.mkMerge [
          (lib.mapAttrs' (
            stackName: _:
            lib.nameValuePair "podman-network-${stackName}" {
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [ pkgs.podman ];
              script = "podman network create --ignore ${stackName}";
              wantedBy = [ "multi-user.target" ];
            }
          ) config.stacks)

          (lib.listToAttrs (
            map (
              { stackName, cName, ... }:
              lib.nameValuePair "podman-${stackName}-${cName}" {
                requires = [ "podman-network-${stackName}.service" ];
                after = [ "podman-network-${stackName}.service" ];
              }
            ) allContainers
          ))
        ];

        systemd.tmpfiles.rules =
          (lib.mapAttrsToList (_: stack: "d ${stack.dataDir} 0700 root root -") config.stacks)
          ++ lib.concatMap (
            {
              stack,
              cName,
              c,
              ...
            }:
            lib.mapAttrsToList (vName: _: "d ${stack.dataDir}/${cName}/${vName} - - - -") c.volumes
          ) allContainers;
      };
    };
}
