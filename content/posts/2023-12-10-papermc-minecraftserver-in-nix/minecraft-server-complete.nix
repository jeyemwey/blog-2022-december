{ pkgs, lib, ... }:
let
  userlist = [
    {
      name = "jeyemwey";
      uuid = "3e621ad8-effe-4810-88fd-51767e785aa1";
      level = 4;
      bypassPlayerLimit = true;
    }
    {
      name = "user-ohne-op-rechte";
      uuid = "79584ed8-ce2a-4317-a7f6-aacc313a8761";
      level = 0;
      bypassPlayerLimit = false;
    }
  ];
  operators = lib.filter (player: player.level > 0) userlist;
  whitelist = map (p: removeAttrs p [ "level" "bypassPlayerLimit" ]) userlist;

  unifiedMetrics.plugin = pkgs.stdenv.mkDerivation rec {
    name = "unifiedMetricsPlugin";
    version = "platform-bukkit-0.3.8";
    src = pkgs.fetchurl {
      url =
        "https://github.com/Cubxity/UnifiedMetrics/releases/download/v0.3.8/unifiedmetrics-${version}.jar";
      hash = "sha256-Cx7EwOU0wv0JqNUuY0T60Nsw3abLvZuuje4rbG64YKA=";
    };
    # Only download the script and run the installer
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/unifiedMetrics.jar
    '';
  };
  unifiedMetrics.configuration = {
    server = { name = "global"; };
    metrics = {
      enabled = true;
      driver = "prometheus";
      collectors = {
        systemGc = true;
        systemMemory = true;
        systemProcess = true;
        systemThread = true;
        server = true;
        world = true;
        tick = true;
        events = true;
      };
    };
  };
  unifiedMetrics.prometheusConfiguration = {
    mode = "HTTP";
    http = {
      host = "127.0.0.1";
      port = 9125;
      authentication = {
        scheme = "NONE";
        username = "username";
        password = "password";
      };
    };
  };

  squaremap.plugin = pkgs.stdenv.mkDerivation rec {
    name = "squaremapPlugin";
    version = "paper-mc1.20.2-1.2.1";
    src = pkgs.fetchurl {
      url =
        "https://github.com/jpenilla/squaremap/releases/download/v1.2.1/squaremap-${version}.jar";
      hash = "sha256-9c3w+rAezleo6ODyI9M1y/eEjg3gs8+rU9ZjjJV7LSQ=";
    };
    # Only download the script and run the installer
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/squaremap.jar
    '';
  };
  squaremap.configuration = {
    "config-version" = 1;
    settings = {
      "internal-webserver".enabled = false;
      "web-directory".path = "/var/www/minecraft-map";
      ui.sidebar.pinned = "pinned";
      "auto-update" = true;
    };
    "world-settings" = {
      default.map = {
        enabled = true;
        zoom = {
          maximum = 5;
          default = 3;
          extra = 4;
        };
      };
      "minecraft:the_nether".map.enabled = true;
      "minecraft:the_end".map.enabled = true;
    };
  };
in {
  networking.firewall.allowedTCPPorts = [ 25565 ];
  users.users.minecraft-server = {
    name = "minecraft-server";
    isSystemUser = true;
    group = "minecraft-server";
    extraGroups = [ "nginx" ];
  };
  users.groups.minecraft-server = { };

  systemd.services."minecraft-server" = {
    description = "Minecraft Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.papermc}/bin/minecraft-server -Xmx2G -Xms1G";
      Restart = "always";
      WorkingDirectory = "/var/lib/minecraft-server";
      StateDirectory = "minecraft-server";

      User = "minecraft-server";
      Group = "minecraft-server";
    };

    preStart = ''
      ln -sf ${
        builtins.toFile "eula.txt" ''
          # eula.txt managed by NixOS Configuration
          eula=true
        ''
      } eula.txt

      ln -sf ${builtins.toFile "ops.json" (builtins.toJSON operators)} ops.json
      ln -sf ${
        builtins.toFile "whitelist.json" (builtins.toJSON whitelist)
      } whitelist.json

      mkdir -p plugins/UnifiedMetrics/driver

      ln -sf ${unifiedMetrics.plugin}/bin/unifiedMetrics.jar ./plugins/unifiedMetrics.jar
      cp ${
        builtins.toFile "config.yml"
        (builtins.toJSON unifiedMetrics.configuration)
      } ./plugins/UnifiedMetrics/config.yml || true
      cp ${
        builtins.toFile "prometheus.yml"
        (builtins.toJSON unifiedMetrics.prometheusConfiguration)
      } ./plugins/UnifiedMetrics/driver/prometheus.yml || true

      mkdir -p plugins/squaremap/
      ln -sf ${squaremap.plugin}/bin/squaremap.jar ./plugins/squaremap.jar
      cp ${
        builtins.toFile "config.yml" (builtins.toJSON squaremap.configuration)
      } ./plugins/squaremap/config.yml || true
    '';
  };

  systemd.tmpfiles.rules =
    [ "d /var/www/minecraft-map 0755 minecraft-server nginx" ];

  security.acme = {
    defaults.email = "meine-email-adresse@example.com";
    acceptTerms = true;
  };
  services.nginx = {
    enable = true;
    virtualHosts."meine-domain.example.com" = {
      root = "/var/www/minecraft-map";

      enableACME = true;
      forceSSL = true;
    };
  };
}
