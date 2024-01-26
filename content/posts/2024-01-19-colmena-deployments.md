---
title:  "NixOS-Deployments mit Colmena"
description: Die volle Stärke von Infrastructure as Code nutzen
date:   2024-01-19
tags: [tech, nixos]
---

Ich habe [Colmena](http://colmena.cli.rs/unstable) im Sommer 2022 [im Rahmen des VCP-Bundeslagers](https://git.clerie.de/clerie/vcp-bula-nixfiles) kennengelernt und war begeistert und ehrlich gesagt ein wenig überwältigt von der Power, die das Tool (und NixOS allgemein) mitbringt.
Colmena ist ein Deployment-Tool, um mehrere NixOS-Computer zu verwalten.
Es ist mit Flakes nutzbar, wodurch auch mehrere `nixpkgs`-Versionen unterstützt werden.

In diesem Artikel möchte ich NixOS und Colmena für Einsteiger verständlich vorstellen.
Je komplexer eine Colmena-Umgebung ist, desto überwältigender ist sie auch - darum finde ich es wichtig, die Entwicklung einer Umgebung von Anfang an darzustellen.

Dieser Artikel hat mehrere Teile (TODO), die unterschiedliche Features darstellen.
Hierbei sollte jeder Abschnitt einzeln hilfreich sein, und auch in anderen NixOS-Deployments helfen.

{{< toc >}}

## Das Grundgerüst

Am Anfang steht eine `flake.nix`-Datei, die zwei Outputs, nämlich das `colmena`-Schema und eine `devShells.default` hat.
Zum Anfang habe ich einen Host, den ich intern "jeffrey" genannt habe.
"jeffrey" hat bereits eine NixOS-Installation, die ich mich mit SSH erreichen kann.

```nix
{
  inputs = {
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs@{ flake-utils, nixpkgs_stable, ... }:
    {
      colmena = {
        meta = let
          overrides = {
            system = "aarch64-linux";
            overlays = [ ];
            config.allowUnfree = true;
          };
          stable = import nixpkgs_stable overrides;
        in {
          nixpkgs = stable;

          nodeNixpkgs = { jeffrey = stable; };
        };

        defaults = { pkgs, ... }: { imports = [ ./hosts/defaults ]; };

        jeffrey = { modulesPath, ... }: {
          deployment = {
            targetHost = "jeffrey.infra.iamjannik.me";
            targetUser = "root";
          };

          imports = [ ./hosts/jeffrey.infra.iamjannik.me ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs_stable.legacyPackages.${system};
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [ colmena nixfmt wireguard-tools ];

            shellHook = ''
              echo "Welcome to the nixos-server-configs!"

              export EDITOR="nvim"
            '';
          };
      });
}
```

In dieser Datei steht jetzt schon eine ganze Menge drin, das natürlich auch auf den eigenen User angepasst werden muss.
In der Host-Definition in `jeffrey.deployment.target*` steht drin, wie Colmena sich mit dem Server verbinden soll, und dabei wird auch die aktuelle SSH-Config geladen.

Außerdem werden zwei weitere Dateien geladen und hier habe ich ein Dateischema aufgegriffen, dass ich bei einigen anderen, öffentlich verfügbaren Konfigurationen gefunden:

```
.
├── README.md
├── flake.lock
├── flake.nix
└── hosts
    ├── defaults
    │   ├── default.nix
    │   ├── ssh-server.nix
    │   └── users.jannik.nix
    └── jeffrey.infra.iamjannik.me
        ├── default.nix
        └── hardware-configuration.nix
```

Die jeweilige `default.nix` importiert jeweils die restlichen Dateien in dem Ordner, zum Beispiel in der `./hosts/defaults/default.nix` muss so nicht über mehrere Ordner-Ebenen gelinked werden:

```nix
{ ... }: {
  imports = [
    ./ssh-server.nix
    ./users.jannik.nix
  ];
}
```

Außerdem hat jeder Host eine `hardware-configuration.nix`, die beim Installieren von NixOS auf dem Server generiert wird. Hier stehen auch IP-Interface-Konfigurationen, Dateisysteme usw. drin.

### Die Default-Konfiguration

Die folgende Konfiguration wird auf jeden Host installiert, der über das Deployment gemanaged wird.
Das ist für mich eine der besonderen Funktionen von NixOS, denn das erlaubt die stressfreie und einheitliche Implementation von neuen Features auf jedem Host.

Der SSH-Server auf dem Server wird folgendermaßen auf meinen Hosts konfiguriert:

```nix
{ ... }: {
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB - Host vom einen Rechner -"
    "ssh-ed25519 AAAAC - Host vom anderen Rechner -"
  ];
}
```

Außerdem gibt es eine User-Config, in der auch schon Comfort-Tools zum Debuggen installiert werden:

```nix
{ pkgs, ... }: {
  users.users.jannik = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB - Host vom einen Rechner -"
      "ssh-ed25519 AAAAC - Host vom anderen Rechner -"
    ];
    hashedPassword = " = Output von `mkpasswd -m sha-256 'secret_passw*rd'` = ";

    shell = pkgs.zsh;
    packages = with pkgs; [ zsh htop neovim nettools jq tree ];

  };

  programs.zsh.enable = true;
  programs.neovim = {
    vimAlias = true;
    viAlias = true;
  };
}
```

### Konfigurationen anwenden

Diese Konfiguration kann ich nun über die `colmena`-CLI installieren. Aus dem Root-Verzeichnis (das mit der `flake.nix`-Datei) wird der folgende Befehl aufgerufen:

```shell
# Zum Öffnen der Entwicklungs-Umgebung / "devShell"
nix develop

colmena apply --build-on-target --on jeffrey
```

Wenn Fehler auftreten, kann der Colmena-Befehl mit `--show-trace` und `--verbose` erweitert werden.

Wenn mehrere Computer gleichzeitig ausgerollt werden, kann das `--build-on-target`-Flag entfernt werden.
Die Konfiguration wird dann auf dem Rechner gebaut, der gerade Colmena ausführt. Das ist besonders hilfreich, wenn du eigene Software installieren willst, die dann nur einmal und nicht auf jedem Node einzeln kompiliert werden muss.

## Ein einfacher Nginx-Server

In meiner Host-Konfiguration `./hosts/jeffrey.infra.iamjannik.me/default.nix` kann ich nun Services implementieren, zum Beispiel kann ich einen Nginx-Service aufmachen, der eine Webseite bereitstellt:

```nix
{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  
  services.nginx.enable = true;
  services.nginx.virtualHosts."www.iamjannik.me" = {
    forceSSL = true;
    enableACME = true;

    root = "/var/www/iamjannik.me/";
  };
}
```

Diese Config ist super einfach gehalten, denn was hier nicht beschrieben wird, sind Firewalllöcher, Nginx-Gzip-Configs, TLS-/ACME-Settings und so weiter.
Da diese Sachen für alle Server in meinem Cluster gleich ist, verschiebe ich das in eine `./hosts/defaults/nginx.nix`, die dann aus der `default.nix` im Ordner geladen wird:

```nix
{ config, lib, ... }: {
  networking.firewall.allowedTCPPorts =
    lib.mkIf config.services.nginx.enable [ 80 443 ];

  security.acme = {
    defaults.email = "jannik+letsencrypt@outlook.com";
    acceptTerms = true;
  };

  services = {
    nginx = {
      enableReload = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };
  
  users.groups.nginx.members =
    lib.mkIf config.services.nginx.enable [ "jannik" ];
}
```

Man sieht hier, dass die bestehende `config` des jeweiligen Hosts als Parameter genutzt wird und _nur in dem Fall_, dass einer der Dienste `services.nginx.enable = true;` setzt, wird die Firewall geöffnet.
Alle weitere Config wird ebenfalls nur in dem Fall, dass Nginx oder ein anderer ACME-Service sie braucht, verwendet.
Sie tut aber auch nicht weh, wenn sie nicht verwendet wird.

Ich kann mich nun auf den Server per SSH anmelden und eine `index.html`-Datei beschreiben:

```shell
ssh jannik@jeffrey.infra.iamjannik.me
echo "<h1>Hello there!</h1>" > /var/www/iamjannik.me/index.html
```

## Secrets

Die Verwaltung von geheimen Daten wie Passwörtern ist ein komplexes Thema bei NixOS, denn standardmäßig befindet sich jede Konfiguration, die wir bis gerade entwickelt haben, im `/nix/store` und dieser ist _world-readable_.
Das heißt, dass jede Anwendung und jeder User, der Zugang auf den Server hat, alle Konfigurationen und alle Programme, die installiert sind oder waren, lesen kann.
Secrets hingegen sollen nur von einer kleineren Anzahl, idealerweise nur dem Service, der sie wirklich benötigt, gelesen werden können.
