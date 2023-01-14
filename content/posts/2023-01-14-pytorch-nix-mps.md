---
title:  "PyTorch environment with nix flakes and Metal Performance Shaders (MPS)"
description: ""
date:   2023-01-14
tags: [tech]
---

TODO: REPLACE NIX WHEN IT ACTUALLY WORKS!

In most uni courses regarding Machine Learning, I was introduced to use either [TensorFlow](https://www.tensorflow.org) or [PyTorch](https://pytorch.org) in combination with Jupyter Notebooks in Google Colab.
Google Colab is a great hosted version of Jupyter, as it allows students to run their assigned tasks without having to buy computers that heat the entire building.
Anyways, I wanted to try to run Jupyter Notebooks locally with PyTorch, and since I fell in the nix hole on my Mac recently, that had to be done using nix flakes.

I started out with [Ben Lovy's Workstation Post](https://dev.to/deciduously/workspace-management-with-nix-flakes-jupyter-notebook-example-2kke) from October 2021 and that brought a working Jupyter lab by running `nix develop` in the browser.
However, the computing performance for machine learning was quite bad, especially training and evaluating tensors took forever, compared to the CUDA performance from Google Cloud.
Poking around, it was quickly apparent why:

```python
device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
device
#=> device(type='cpu')
```

Yikes.

Apple's SOCs, of course, do not support CUDA, so I couldn't use those device classes for evaluating the datasets.
Thankfully for me, [PyTorch 1.12](https://pytorch.org/blog/pytorch-1.12-released/#prototype-introducing-accelerated-pytorch-training-on-mac) introduced support for Apple's Metal Performance Shader (MPS) architecture, if PyTorch was compiled with the appropriate flag (`USE_MPS`).

This resulted in my modified `flake.nix`:

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          (python3.withPackages (ps: with ps; let
            torch = pytorch.overrideAttrs (_: { USE_MPS = "1"; });
          in
          [
            ipython
            jupyter
            numpy
            pandas
            torch
            (torchvision.override { inherit torch; })
            tqdm
          ]))
        ];
        shellHook = "jupyter notebook";
      };
    }
  );
}
```

Since we have to override parts of the `python310Packages.torch` package, it will not be available in the cache and PyTorch needs to be compiled from stratch.
On my M1 MacBook Air, this took around 30 to 40 minutes, and was only needed the first time.

With that change, we can initialize PyTorch and set up a device ([source of code](https://pytorch.org/docs/stable/notes/mps.html)):
```python
if not torch.backends.mps.is_available():
    if not torch.backends.mps.is_built():
        print("MPS not available because the current PyTorch install was not "
              "built with MPS enabled.")
    else:
        print("MPS not available because the current MacOS version is not 12.3+ "
              "and/or you do not have an MPS-enabled device on this machine.")

else:
    mps_device = torch.device("mps")
```

Big thanks to [xanderio](https://xanderio.de) who helped me trememdiously along the way.
