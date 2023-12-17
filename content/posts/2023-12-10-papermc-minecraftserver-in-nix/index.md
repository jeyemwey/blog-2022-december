---
title:  "PaperMC-Minecraftserver in NixOS"
description: Deklarative Blockspiele mit Nix
date:   2023-12-17
tags: [tech]
---

In diesem Posting möchte ich beschreiben, wie man einen Minecraftserver mit PaperMC und konfigurierbare Plugins auf NixOS installieren kann. Dazu nehme ich die Pakete `papermc` und `nginx` aus nixpkgs (Revision `bf744fe90419885eefced41b3e5ae442d732712d`, also unstable) und baue die Plugins über eigene Derivations.

Die Anleitung richtet sich an Anfänger von NixOS, da ich selbst viel über dieses Projekt gelernt habe. Einiges kann wahrscheinlich einfacher oder eleganter gelöst werden, ich freue mich über Zusendungen per Mail oder Fediverse, um Updates zu schreiben.

Die Anleitung hat fünf Teile, die aufeinander aufbauen:

1. [Das Grundgerüst](#das-grundgerüst)
2. [Whitelist und Operators](#whitelist-und-operators)
3. [Metrics](#metrics)
4. [Webkarten](#webkarten)
5. [Fazit](#fazit)

## Das Grundgerüst
Die Basis des Services ist eine `.nix` file, die über ein `imports = [ ./minecraft-server.nix ];` in die NixOS-Konfiguration inkludiert wird. Diese Files veröffentlichen eine Funktion, welche einen Teil einer Konfiguration zurückgibt. Den Anfang macht ein eigener systemd-Service, der den Server startet:

```nix
{ pkgs, lib, ... }: {
  networking.firewall.allowedTCPPorts = [ 25565 ];
  users.users.minecraft-server = {
    name = "minecraft-server";
    isSystemUser = true;
    group = "minecraft-server";
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
    '';
  };
}
```

Mit diesem Code wird das Paket `pkgs.papermc` geladen, welches eine Laufzeitabhängigkeit von einer _hier nicht weiter spezifizierten_ JRE hat[^1].
Der Nix-Code erstellt einen systemd-Service mit einem `preStart`-Skript, das eine `eula.txt` ins Working Directory symlinkt. Diese Datei wird mit `builtins.toFile(name, content)` zunächst in den Nix-Store gelegt und erst beim ersten Starten in das Working Directory gelegt, in das `minecraft-server.jar` schaut.

[^1]: Die JRE-Abhängigkeit wird über das `makeWrapper`-Skript [in der Paketbeschreibung](https://github.com/NixOS/nixpkgs/blob/b4372c4924d9182034066c823df76d6eaf1f4ec4/pkgs/games/papermc/default.nix#L27C32-L27C32). Durch diesen Link entfällt das Problem, dass verschiedene Anwendungen auf verschiedene Java-Versione vertrauen, was häufig mit Containern gelöst wird.

Außerdem definieren wir einen User `minecraft-server` mit dazugehöriger Gruppe, welcher den Service startet. systemd hat zwar ein Feature für dynamische User, [und ich empfehle jedem den großartigen Writeup  von pid_eins](https://0pointer.net/blog/dynamic-users-with-systemd.html), aber das [Publishen der Webkarten](#webkarten) wird damit leider etwas komplexer.

## Whitelist und Operators
Da mein Server nur für eine kleine Community sein soll, hat er eine Whitelist und eine Operators-Liste. Diese pflege ich als Nix-Liste im `let`-Block. Weil es eine Datei in meinem Infra-Repository ist, kann ich sie nun versionieren, etc.

```nix
{ pkgs, lib, ... }: let
  playerlist = [
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
  operators = lib.filter (player: player.level > 0) playerlist;
  whitelist = map (p: removeAttrs p [ "level" "bypassPlayerLimit" ]) playerlist;
in {
  # ... alles von vorher ...
  systemd.services."minecraft-server" = {
    # ... alles von vorher ...
    preStart = ''
      ln -sf ${
        builtins.toFile "eula.txt" ''
          # eula.txt managed by NixOS Configuration
          eula=true
        ''
      } eula.txt

      ln -sf ${builtins.toFile "ops.json" (builtins.toJSON operators)} ops.json
      ln -sf ${builtins.toFile "whitelist.json" (builtins.toJSON whitelist)} whitelist.json
    '';
  };
}
```

Hier werden zwei Fliegen mit einer Klappe geschlagen: Die `whitelist.json` nimmt nur Namen und UUID der gewhitelisteten User, die Attribute `level` und `bypassPlayerLimit` werden darum entfernt.
Und die Operators sind alle gewhitelisteten User mit _Level über Null_.
Im Sinne von Don't Repeat Yourself muss nun bei einem Username-Change nur eine Stelle angefasst werden [^2].

[^2]: Das kommt zwar selten genug vor, aber es geht ja auch nicht darum, alles möglichst einfach zu machen :D

Im Prestart werden die beiden Configurations wie zuvor mit der Eula übernommen.
Das `ln` übernimmt die Dateiberechtigungen aus dem Nix-Store, der zwar World-Readable ist, jedoch keine Änderungen von Programmen zulässt.
Hierdurch sind `/op <name>` etc. im Spielechat leider nicht mehr nutzbar geworden. Die NixOS-Config bleibt die Single-Source-of-Truth.

Beim Ändern der Konfigurationen sieht die Restart-Funktionalität von `sudo nixos-rebuild switch`, dass sich etwas am Service geändert hat, und (wenn mein Kopf sich das richtig zusammenreimt) passiert das über diesen Weg: 

1. neuer Whitelist-Eintrag
2. &rarr; neue `whitelist.json`
3. &rarr; neuer Hash im `/nix/store/...`-Pfad für die Whitelist
4. &rarr; Änderung im `preStart` Command des Servers
5. &rarr; neuer Hash im `/nix/store/...`-Pfad für die Service-Beschreibung
6. &rarr; Neustart des Services

## Metrics

Seit ich in den Nix-Topf gefallen bin, möchte ich immer auch Metriken mitmessen, und bei Ausfällen informiert werden.
Glücklicherweise gibt es ein [Metrics-Plugin für PaperMC](https://hangar.papermc.io/cubxity/UnifiedMetrics), welches sowohl mit Prometheus als auch mit InfluxDB spricht.

Bei PaperMC werden alle verfügbaren Plugins in Form von `.jar`-Files aus dem `$WORKDIR/plugins`-Ordner geladen.
Das Plugin-Binary kommt aber aus dem Internet und muss deswegen vorher validiert werden. Dazu setzen wir den Source Hash zunächst auf `lib.fakeSha256` und schauen uns die Fehlermeldung an, die Bauen der Derivation generiert wird [^3].

[^3]: Gibt es da wirklich keinen besseren Weg? `nix-prefetch-url` gibt mir immer nur Hashes, die beim Bauen als falsch zurückkommen.

Nun können wir eine eigene Derivation im `let`-Block erstellen, welche das JAR läd und im Nix-Store bereitstellt:

```nix
unifiedMetrics.plugin = pkgs.stdenv.mkDerivation rec {
  name = "unifiedMetricsPlugin";
  version = "platform-bukkit-0.3.8";
  src = pkgs.fetchurl {
    url = "https://github.com/Cubxity/UnifiedMetrics/releases/download/v0.3.8/unifiedmetrics-${version}.jar";
    hash = "sha256-Cx7EwOU0wv0JqNUuY0T60Nsw3abLvZuuje4rbG64YKA=";
  };
  # Only download the script and run the installer
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/unifiedMetrics.jar
  '';
};
```

Das Plugin benötigt noch weitere Konfiguration, welche wir in der Nix-Sprache bereitstellen können. Was alles beschrieben wird, kann [in Cubxity's Dokumentation](https://docs.cubxity.dev/docs/unifiedmetrics/intro) nachgelesen werden.

```nix
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
```

In der `preStart` vom Service wird nun alles in das Working-Directory kopiert/gesymlinkt, wobei ich festgestellt habe, dass das Plugin beim Start versucht, in die Konfigurationsdateien zu schreiben, und sich bei Symlinks quer legt. Sonst ist das Verhalten sehr ähnlich zur `eula.txt` und den anderen Konfigurationen:

```nix
preStart = ''
  mkdir -p plugins/UnifiedMetrics/driver
  ln -sf ${unifiedMetrics.plugin}/bin/unifiedMetrics.jar ./plugins/unifiedMetrics.jar
  cp ${builtins.toFile "config.yml" (builtins.toJSON unifiedMetrics.configuration)} ./plugins/UnifiedMetrics/config.yml || true
  cp ${builtins.toFile "prometheus.yml" (builtins.toJSON unifiedMetrics.prometheusConfiguration)} ./plugins/UnifiedMetrics/driver/prometheus.yml || true
  
  # ...und der Rest...
'' 
```

Nach dem Starten des Servers sollte auf dem Server lokal ein HTTP-Server erreichbar sein, der mit...

```shell
curl "http://127.0.0.1:9125/metrics"
```
...testbar ist.
Von "außen" ist er nicht erreichbar, einerseits, weil der Port nicht in `networking.firewall.allowedTCPPorts` steht, und anderseits weil die Anwendung nur auf dem lokalen Interface lauscht. Da dieser Server jedoch als Plugin in der Minecraft-Java-VM läuft, würde ich es nicht empfehlen, diese Route öffentlich zugänglich zu machen.

Wie die Daten zum Prometheus kommen, sprengt ein wenig den Scope dieses Beitrags, ich möchte jedoch noch auf das vorbereitete [Grafana-Dashboard vom Plugin](https://grafana.com/grafana/dashboards/14756-unifiedmetrics-0-3-x-prometheus/) hinweisen.

## Webkarten

Ein weiteres Plugin, das ich gerne verwenden möchte, heißt Squaremap und rendert eine Webkarte aus den drei Welten (Overworld, Nether, End).

Auch dieses Plugin bringt einen eigenen Webserver mit sich, den wir aber nicht verwenden werden [^4], stattdessen soll das Plugin in einen geteilten Ordner schreiben, den der Webserver of Choice (bei mir nginx) dann lesen kann.
Die Installation des Plugins ähnelt sich sehr dem vorherigen, wobei in der Konfiguration ein WebRoot-Ordner definiert wird, den wir später verwenden werden.

[^4]: Einerseits gehts hier wieder darum, die Server-Java-VM möglichst klein zu halten, anderseits lauscht in meiner Konfiguration bereits ein Nginx auf den Web-Ports 80 und 443, der dann nur um einen Virtual Host erweitert wird. Sämtliches TLS, Monitoring und Hardening, das eh schon konfiguriert ist, kann dann einfach umsonst mitgenutzt werden.

Im `let`-Block:

```nix
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
```

Und im `preStart`, wobei auch hier ein Kopieren das testweise Schreiben durch die Anwendung ermöglicht. Das ist zwar nicht unbedingt notwendig, sonst wirft das Plugin jedoch eine Exception ins Log.

```nix
preStart = ''
  mkdir -p plugins/squaremap/
  ln -sf ${squaremap.plugin}/bin/squaremap.jar ./plugins/squaremap.jar
  cp ${builtins.toFile "config.yml" (builtins.toJSON squaremap.configuration)} ./plugins/squaremap/config.yml || true
'';
```

Damit PaperMC in das Web-Verzeichnis schreiben kann, muss der Service-User in der `nginx`-Gruppe sein und der Service darein schreiben können. Dazu:

```nix
users.users.minecraft-server = {
  name = "minecraft-server";
  isSystemUser = true;
  group = "minecraft-server";
  extraGroups = [ "nginx" ];
};
users.groups.minecraft-server = { };

systemd.tmpfiles.rules = [ "d /var/www/minecraft-map 0755 minecraft-server nginx" ];
```

Außerdem müssen wir dem Nginx über diesen Virtual Host informieren:
```nix
security.acme = {
  defaults.email = "meine-email-adresse@example.com";
  acceptTerms = true;
};
services.nginx = {
  enable = true;
  virtualHosts."mein-blockspiel-server.example.com" = {
    root = "/var/www/minecraft-map";

    enableACME = true;
    forceSSL = true;
  };
};
```
Der `<name>` "mein-blockspiel-server.example.com" in Verbindung mit `enableACME = true` und den `security.acme`-Regeln versucht, ein TLS-Zertifikat für diese Domain zu erstellen und über Let's Encrypt signieren zu lassen. Lies dazu auch [das NixOS-Manual über ACME](https://nixos.org/manual/nixos/stable/#module-security-acme).

Abschließend fehlt uns noch ein Firewall-Loch für die Ports 80 (plain HTTP) und 443 (HTTPS). Dazu passen wir die Zeile `networking.firewall.allowedTCPPorts` an:

```nix
networking.firewall.allowedTCPPorts = [ 80 443 25565 ];
```

Wenn wir nun im Browser deine Domain mit dem Server aufrufen, sollten wir eine 2D-Karte mit Player-Heads und der Welt sehen. Die UI ist super detailliert einstellbar, vor allem was Zoom-Stufen angeht. Hier muss man ein wenig herumspielen, um eine Balance zwischen Nützlichkeit und Speicherbedarf der Karten-PNGs zu finden.

## Fazit

Ich habe beim Rumtüfteln sehr viel über systemd, über Nix und NixOS, und über PaperMC gelernt, und hoffe, dieses Wissen ein wenig weitertragen zu können.

Abschließend ist [hier noch die komplette Konfiguration](./minecraft-server-complete.nix).

Jetzt bräuchte ich nur noch Zeit, auch tatsächlich Minecraft zu spielen.
