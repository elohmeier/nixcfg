{
  config,
  lib,
  pkgs,
  ...
}:

let
  autoConnect = config.nixcfg.tailscale.authkeyFile != null;
in
{
  options = {
    nixcfg.tailscale.authkeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the Tailscale authentication key file used for automatic login.";
    };
    nixcfg.tailscale.certPostScript = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "systemctl --no-block try-reload-or-restart nginx.service";
      description = "Script to run after acquiring the Tailscale host TLS certificate.";
    };
  };

  config = {
    services.tailscale = {
      enable = true;
      permitCertUid = "tailscale-cert";
    };

    services.fail2ban.ignoreIP = [ "100.64.0.0/10" ];

    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };

    systemd.services.tailscale-autoconnect = lib.mkIf autoConnect {
      description = "connect to tailscale";

      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = [ "multi-user.target" ];

      path = [
        config.services.tailscale.package
        pkgs.jq
      ];

      serviceConfig.Type = "oneshot";

      script = ''
        set -e

        # get the backend state, e.g. `Running` or `NeedsLogin`
        BACKEND_STATE=$(tailscale status --json | jq -r '.BackendState')

        # abort when not `NeedsLogin`
        if [ "$BACKEND_STATE" != "NeedsLogin" ]; then
            echo "tailscale backend not in NeedsLogin state, aborting"
            exit 0
        fi

        echo "logging in to tailscale using authkey from ${config.nixcfg.tailscale.authkeyFile}"
        tailscale up --authkey file:"${config.nixcfg.tailscale.authkeyFile}"
      '';
    };

    users.groups.tailscale-cert = { };
    users.users.tailscale-cert = {
      group = "tailscale-cert";
      isSystemUser = true;
    };

    systemd.services.tailscale-cert = {
      description = "fetch tailscale host TLS certificate";
      after = [
        "network-online.target"
        "tailscale.service"
      ] ++ lib.optional autoConnect "tailscale-autoconnect.service";
      wants = [
        "network-online.target"
        "tailscale.service"
      ] ++ lib.optional autoConnect "tailscale-autoconnect.service";
      wantedBy = [ "multi-user.target" ];

      path = [
        config.services.tailscale.package
        pkgs.jq
      ];

      script = ''
        set -e

        # get the backend state, e.g. `Running` or `NeedsLogin`
        BACKEND_STATE=$(tailscale status --json | jq -r '.BackendState')

        # abort when not running
        if [ "$BACKEND_STATE" != "Running" ]; then
            echo "tailscale backend not running, aborting"
            exit 0
        fi

        # get the DNS name, e.g. `myhost.pug-coho.ts.net.`
        DNS_NAME=$(tailscale status --json | jq -r '.Self.DNSName')

        # check if DNS name is set
        if [ -z "$DNS_NAME" ]; then
            echo "tailscale DNS name not set, aborting"
            exit 0
        fi

        # trim trailing dot
        DNS_NAME=''${DNS_NAME%.}

        # acquire certificate
        tailscale cert "$DNS_NAME"

        # update permissions
        chmod 640 "$DNS_NAME.key"
        chmod 640 "$DNS_NAME.crt"
      '';

      serviceConfig =
        {
          Group = "tailscale-cert";
          StateDirectory = "tailscale-cert";
          Type = "oneshot";
          User = "tailscale-cert";
          WorkingDirectory = "/var/lib/tailscale-cert";
        }
        // lib.optionalAttrs (config.nixcfg.tailscale.certPostScript != "") {
          "ExecStartPost" = "+${pkgs.writeShellScript "tailscale-cert-post" config.nixcfg.tailscale.certPostScript}";
        };

      startAt = "daily";
    };
  };
}
