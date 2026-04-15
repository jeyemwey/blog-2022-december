
---
title: "Application sandboxing with nono in Home-Manager for the Mac"
date: 2026-04-23
slug: application-sandboxing-with-nono
description: Making use of kernel-level enforcement to reduce the blast radius of untrusted applications.
tags: [tech, nixos, english]
---

I like using [home-manager](https://nix-community.github.io/home-manager/) to manage my home folder, or at least the config files in it that don't come with a strong gui. It gives me a sense of ownership of the configuration, forces me to make myself familiar with the application that I'm trying to configure, and makes the new-found love for some new tool or shortcut available on all of my computers, in a consistent manner (even between Mac and Linux!).

So when [Rudi recently posted about](https://blog.bott.im/taming-the-beast-how-to-lock-in-your-ai-agent/) the [`nono` sandboxing tool](https://nono.sh), I, of course, wanted to use it to the fullest and with my config and package manager of choice.

First off: `nono` is at a state where it's constantly making changes, so fast that [the nixpkgs maintainers seem to have a hard time catching up](https://github.com/NixOS/nixpkgs/pull/509106). I figure this may also apply to the config schema, so please note that I'm using the `0.39.0` version for this post. Against my usual approach, I'm using brew to install the software, which is an [official way of installation](https://nono.sh/docs/cli/getting_started/installation) and should quickly get new package updates. Not the "pure" way of using nix, but I'll take it.

`nono` uses system/kernel libraries to restrict applications to specific capabilities, i.e. making sure that an editor can only ever read the current working directory (and configured, global app configuration files), or that a script does not reach the internet or can't start subshells.

As advertised, I'm also using it to sandbox LLM """"agents""""[^1], which would, if not confined, be able to read much more than I would ever want them to.
When talking to my colleagues, everyone seems to have their own judgement of how much access they want to offer to the LLM, some are drawing a line at direct file edits, while others are happy to hand over their SSH keys to debug a private linux server.
My current stance is that I'm okay with handing over the repository that I'm currently in, except for files that would typically contain secrets like `.env`[^2].
Also, I can't be bothered to be asked for permission when calling "not-dangerous" commands like `find` or `awk`, arguing that being asked for those simple commands can introduce Consent Fatigue[^3]. On the other hand, when the the LLM wants to call tests or introduce new dependencies, that's a case of explicit consent, and I think that makes sense.

[^1]: I still hate the word, agents used to be spies like James Bond who make friends with you and then use what you told them for their own ends. Oh. Oh wait! Also, please don't argue with me about using LLMs in general, at least not today.
[^2]: There are _a lot_ of different files that may contain extra-sensitive information, including any and all `.age` files, spring's `/application.*\.y[a]?ml/` files, container compose files, etc. You probably know that for the programming language that you're using, so I'll spare you the details here.
[^3]: Knowing full-well that both of those commands can fork new programs and mess with files, but that should still be protected.

To configure `nono`, you can define profiles which are inheritable. Those profiles need to be placed in `$HOME/.config/nono/profiles`.
Together with home-manager, you arrive at something like the following, extending the "claude-code" profile[^4].
Since the profile name is going to be used in multiple places, I keep it in a `let ...; in` statement.

[^4]: I expect that the upstream changes to the claude-code profile are more up-to-date than I could ever be, so I'm actively not replacing the given profile here.

```nix
{ config, lib, ... }: let
    profileName = "my-special-profile";
in {
  xdg.configFile."nono/profiles/${profileName}.json".text = builtins.toJSON ({
    meta.name = profileName;
    extends = "claude-code";

    # Your changes here!
    filesystem = {
      read = [
        # This seems necessary so nono can call applications from nixpkgs
        "${config.home.homeDirectory}/.nix-profile/bin/"
      ];
    };

    policy = {
      add_deny_access = [
        # i.e. deny access to a flag file
        "${config.home.homeDirectory}/flag.txt"
      ];
    };
  });
}
```

At this point, you might want to try your profile. After activating the home-manager generation, the json profile file should appear and you can run `nono`:

```shell
nono --profile my-special-profile -- cat $HOME/flag.txt
```

Since this is quite a mouthful, I added a script that does exactly that:

```nix
home.packages = [
  (pkgs.writeShellScriptBin "nono-sandboxed" ''
    #!/usr/bin/env bash
    nono run --allow-cwd --profile ${profileName} -- "$@"
  '')
];
```

This reduces the command to:

```shell
nono-sandboxed cat $HOME/flag.txt
```

As expected, I get the following, negative output:

```txt
  mode supervised (supervisor)
  Applying sandbox...
cat: flag.txt: Operation not permitted

NONO DIAGNOSTIC
────────────────────────
The command failed. This may be due to sandbox restrictions. (exit code 1)

Sandbox denied the following operations:
  file-read-data <<MY HOME>>/flag.txt
```

Quite fun, isn't it? For the final blow, let's add a shell wrap for the Claude TUI. Extra nice: While the `claude-code` package is available through the new command, it isn't added to the nix-profile directly, so there's no accidental typing `claude` and ending up with the unsandboxed version.

```nix
home.packages = [
  (pkgs.writeShellScriptBin "claude-sandboxed" ''
    #!/usr/bin/env bash
    nono run --allow-cwd --profile ${profileName} -- ${lib.getExe pkgs.claude-code}
  '')
];
```

Without going into my exact configuration, especially because I'm really new to sandboxing applications in general, I'm happy with the results so far.

I hope you enjoyed my introduction to `nono` with `home-manager`. :)
