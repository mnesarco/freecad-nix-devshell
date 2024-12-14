<!--
MIT License

Copyright (c) 2024 Frank David Martinez Muñoz <mnesarco>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->

# Build FreeCAD with Nix Flake

This a minimalist Flake to build FreeCAD from source in Linux (other than NixOS) for development.

This Flake is for a devShell where you can build and run FreeCAD.

## 1. Install nix

Doh, https://nixos.org/download/

Nix needs to be configured to support flakes, so add this to your
`/etc/nix/nix.conf` if it is not already there:

```bash
experimental-features = nix-command flakes
```

## 2. Clone this repo

```bash
$ git clone https://github.com/mnesarco/freecad-nix-devshell.git
```

## 3. Activate the nix devShell

```bash
$ cd freecad-nix-devshell
$ nix develop
```

This will take a few minutes the first time and will ultimately
provide you with a complete environment to build FreeCAD

## 4. Clone FreeCAD repo

```bash
$ clone

```

This clones main branch of freecad and update submodules ...

## 5. Configure

```bash
$ config

```

This calls cmake to configure the build dir...


## 6. Build

```bash
$ compile -j8

```

This calls cmake to build freecad binaries.
`-j8` tells cmake to use 8 cores, change as needed.


## 7. Run

```bash
$ freecad

```

This launch the local compiled version. Depending on your
GPU, you need to configure nix first to run OpenGL based
applications, see the OpenGL notes at the end.

## 8. Later on

Any time you need to compile or run, just activate the shell and enjoy:

Compile:
```bash
$ cd freecad-nix-devshell
$ nix develop
$ compile -j8

```

Run:
```bash
$ cd freecad-nix-devshell
$ nix develop
$ freecad

```

## Notes

At the end of the process your directory will looks like this:

```
.
├── build         <-- Local build
├── flake.lock
├── flake.nix
├── FreeCAD       <-- FreeCAD sources cloned from github
├── LICENSE
├── README.md
└── var           <-- FreeCAD home for Mod, Macros, Cache, etc...

```

## OpenGL Notes

In order to run OpenGL Applications from a nix shell, you need to configure
the correct graphic drivers.

Here is the relevant info: https://github.com/soupglasses/nix-system-graphics

The basic instruction is to create a directory (out of our freecad-nix-devshell)
and put a flake.nix file with the following content:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs, system-manager, nix-system-graphics }: {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        nix-system-graphics.systemModules.default
        ({
          config = {
            nixpkgs.hostPlatform = "x86_64-linux";
            system-manager.allowAnyDistro = true;
            system-graphics.enable = true;
          };
        })
      ];
    };
  };
}
```

Then just run the following command inside the directory that you created (i.e. `gl_config`):

```bash
$ cd gl_config
$ sudo env "PATH=$PATH" nix run 'github:numtide/system-manager' -- switch --flake '.'
```

This command activates the OpenGL configuration.

### Nvidia GPUs

As usual, nvidia requires special care. You need to identify the exact version
of your current working nvidia driver and modify the file to include that info.

1. Check your driver version:

```bash
$ cat /proc/driver/nvidia/version
>>> NVRM version: NVIDIA UNIX x86_64 Kernel Module  535.183.01  Sun May 12 19:39:15 UTC 2024
>>> GCC version:  gcc version 12.3.0 (Ubuntu 12.3.0-1ubuntu1~22.04)
```

In this example the driver version is `535.183.01`

2. Modify your flake.inx file with the corresponding info.

```nix
{
  description = "System Manager configuration for OpenGL";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs, system-manager, nix-system-graphics }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };

    in {
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          nix-system-graphics.systemModules.default
          ({
            config = {
              nixpkgs.hostPlatform = "${system}";
              system-manager.allowAnyDistro = true;
              system-graphics = let

                nvidia-drivers =
                  (pkgs.linuxPackages.nvidiaPackages.mkDriver {
                    # use same version as OS version from /proc/driver/nvidia/version
                    version = "535.183.01";
                    sha256_64bit = "sha256-9nB6+92pQH48vC5RKOYLy82/AvrimVjHL6+11AXouIM=";
                    sha256_aarch64 = "";
                    openSha256 = "";
                    settingsSha256 = "";
                    persistencedSha256 = "";
                    patches = pkgs.linuxPackages.nvidiaPackages.production.patches;
                  }).override {
                    libsOnly = true;
                    kernel = null;
                  };

                in {
                  enable = true;
                  package = nvidia-drivers;
                };
            };
          })
        ];
      };
    };

}
```

Then run the command to set the configuration:

```bash
$ cd gl_config
$ sudo env "PATH=$PATH" nix run 'github:numtide/system-manager' -- switch --flake '.'
```

Don't worry about the hash value `sha256_64bit`, the first time you run the command,
it will show an error if the hash doesn't match, but also shows the correct value
so you can update the file and run the command again.