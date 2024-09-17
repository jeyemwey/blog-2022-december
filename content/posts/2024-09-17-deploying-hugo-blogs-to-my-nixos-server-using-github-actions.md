---
title: "Continuous Deployment meines Hugo Blogs zu meinem NixOS-Server mit GitHub Actions"
description: "Der Titel sagt es bereits. Es geht darum, wie ich meinen Blog bei jedem Commit deploye und wie die GitHub Actions- und NixOS-Konfiguration dafür aussieht."
date: 2024-09-17
tags: [tech, nixos]
---


Ich nutze Hugo für diese Webseite (also alles unter dieser Subdomain). Hugo ist ein Programm, das dutzende statische Webseiten aus einzelnen `1970-01-01-blog-entry.md` Einträgen bastelt. Es ist ein bisschen frickelig beim Aufsetzen, vor allem, wenn man Bild-Reihen einbaut, aber wenn es einmal steht, ist es tatsächlich schön.
Die Einträge kann man in Git speichern und die fertigen Dateien über den dümmstmöglichen Weg (S3, Nginx in Basis-Configuration) dem Internet darbieten.

Eines Tages wollte ich aus einem Pfadi-Lager raus bloggen (ist nie was draus geworden, aber bear with me) und dafür idealerweise nur ein `git push` absetzen.
Das ist tatsächlich nicht super komplex, viele Organisationen arbeiten mit _CI/CD_, um ihren Code zu validieren, zu kompilieren und zu verbreiten. Ich muss nur die Build-Beschreibung mit einem Zugang zu meinem Server verbinden und fertig.

## Repository Actions

Ein verbreitetes Modell dafür ist GitHub Actions, was ich auch nutze.
Bei jedem Push fährt ein Container hoch, ein Skript installiert Hugo und baut den Blog, besorgt sich dann einen privaten SSH-Key aus den Action Secrets und läd die Daten ins www-Directory vom Server.

Das Skript sieht etwa so aus:

```yaml
name: Hugo Build

on:
  push:
    branches:
      - main
  workflow_dispatch: # For manual deployments if needed

jobs:
  deploy:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: "0.110.0"

      - name: Build
        run: hugo --minify

      - name: Install SSH Key
        uses: shimataro/ssh-key-action@v2
        with:
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          known_hosts: ${{ secrets.SSH_HOST_KEY }}

      - name: Deploy with rsync
        run: rsync -avz --no-p \
          --omit-dir-times ./public/ \
          github-actions@blog.iamjannik.me:/var/www/blog.iamjannik.me/share
```

Das SSH-Secret-Pair habe ich zuvor auf meinem Laptop erstellt:

```shell
ssh-keygen \
  -t ed25519 \
  -C "your_email@example.com" \
  -f ./id_github-actions
```

Der Inhalt der Datei `./id_github-actions` kommt in das Repository Secret `SSH_PRIVATE_KEY`, den Public Key benötigen wir gleich für die Server-Konfiguration.

Außerdem muss die Action den Server verifizieren. Das passiert per SSH beim ersten Mal, wo du dich mit dem Server verbindest und "yes" tippen musst, hier ein wenig manueller mit dem Befehl, dessen Ausgabe in das Secret `SSH_HOST_KEY` geschrieben wird:

```shell
ssh-keyscan blog.iamjannik.me | grep ed25519
```

## Server Config

Nun muss ich noch den Server so konfigurieren, dass er den Zugang mit diesen Zugangsdaten gewährt, mich in das Webroot Verzeichnis schreiben lässt und den Webroot als Webseite freigibt.
Für meine Server-Konfiguration nutze ich NixOS und ein entsprechendes Modul sieht dann so aus:


```nix
{ ... }:
let
  blogDir = "/var/www/blog.iamjannik.me/share";
  blogUrl = "blog.iamjannik.me";
in {
  users.users.github-actions = {
    isNormalUser = true;
    createHome = false;
    openssh.authorizedKeys.keys = [
      # see private key in ./id_github-actions
      "ssh-ed25519 AAAAC..."
    ];
    # don't offer login via password.
    hashedPassword = null;
  };

  # Create webroot folder and make sure that the user github-actions
  # can write and everyone (i.e. the nginx daemon) can read from it.
  systemd.tmpfiles.rules = [ "d ${blogDir} 0755 github-actions" ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."${blogUrl}" = {
    forceSSL = true;
    enableACME = true;
    root = "${blogDir}";
  };
}
```

### Why not flakes?

Dem geschulten NixOS-Auge wird nun aufgefallen sein, dass ich nicht die reine Lehre nutze und das Blog ja nicht im reproduzierbaren Nix-Baum liegt.
Das wird dazu führen, dass ich beim Neuaufsetzen dieses Servers erstmal eine leere Seite unter der `blog.` Subdomain ausgeben werde.

Idealerweise wird das Blog-Artifakt als Derivation in einer `flake.nix` bereitgestellt und ein `nix flake lock --update-input blog_repo` im Server-Repository ausgeführt.
Beim nächsten Rebuild des Servers läd der Builder das Repository mit der Derivation, besorgt sich Hugo, baut den Blog und linked den WebRoot von Nginx direkt nach `/nix/store`.
Das wäre großartig oder?

Ich halte allerdings dagegen mit:

1. Beim Push ins Blog-Repository wird auch ein neuer Commit ins Server-Config-Repository geschrieben, welches den Git Log pollutet.
2. Das Server-Config-Repository würde einen (defacto) Root-Zugang zum tatsächlichen Host benötigen, um ein `nixos-rebuild switch` durchzuführen. Soweit bin ich persönlich noch nicht, zumal ich noch keine Build-Umgebung für mein NixOS-Setup habe.
3. Auch wenn es durch die NixOS-Environment gesandboxed ist, benötigt der Webserver -- dessen Job es ist, Webseiten zu hosten -- eine Hugo-Installation und, wenn es schlecht läuft, noch einen Go-Compiler, um sich Hugo zu bauen. Das fühlt sich für mich nicht gut an, im besten Fall ist für mich die Webserver-Konfiguration so klein wie es geht, also eigentlich nur der `services.nginx`-Block da oben, und das notwendigste Übel.
4. Wenn ich auf dem Acker [in Korea]({{< ref "2024-01-20-my-jamboree-experience" >}}) sitze und _nur_ einen Blog-Post rausschreiben wollen würde (siehe Problembeschreibung im ersten Abschnitt), möchte ich wahrscheinlich ungerne mir Gedanken darüber machen müssen, wie gerade der Rebuild von meiner gesamten Server-Umgebung läuft. Ich möchte einfach mir in dieser Situation einfach keinen Kopf darum machen müssen, sondern nur die 5 File-Updates für meinen Blog-Eintrag rausschicken.


So. Ich committe das jetzt, pushe es, und bin in <1min live mit dem Artikel. Yay!
