# opennow-flake

Nix flake packaging [OpenNOW](https://github.com/OpenCloudGaming/OpenNOW), an open-source, controller-first GeForce NOW client, from its official Qt AppImage release.

- Version: **1.0.5**
- Systems: `x86_64-linux`, `aarch64-linux`
- License: MIT (upstream)

## Try it

```sh
nix run github:<you>/opennow-flake
# or from a local checkout
nix run /home/hylmi/flakes/opennow-flake
```

## Install on NixOS

Add the input and module to your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opennow.url = "path:/home/hylmi/flakes/opennow-flake";
    opennow.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, opennow, ... }: {
    nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        opennow.nixosModules.default
      ];
    };
  };
}
```

Then rebuild:

```sh
sudo nixos-rebuild switch --flake .#<hostname>
```

OpenNOW appears in your app launcher, and you can also start it from a terminal with `opennow`.

### Other ways to use it

**Overlay** (makes `pkgs.opennow` available):

```nix
nixpkgs.overlays = [ opennow.overlays.default ];
environment.systemPackages = [ pkgs.opennow ];
```

**Package directly:**

```nix
environment.systemPackages = [ opennow.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

**Home Manager:**

```nix
home.packages = [ opennow.packages.${pkgs.stdenv.hostPlatform.system}.default ];
```

## Flake outputs

| Output | Description |
| --- | --- |
| `packages.<system>.opennow` / `default` | The wrapped AppImage |
| `apps.<system>.opennow` / `default` | For `nix run` |
| `overlays.default` | Adds `opennow` to `pkgs` |
| `nixosModules.default` | Applies the overlay and installs OpenNOW system-wide |

## Updating to a new release

1. Change `version` in `package.nix`.
2. Get the new SHA-256 digests from the release:
   ```sh
   gh release view v<version> -R OpenCloudGaming/OpenNOW --json assets \
     -q '.assets[] | select(.name|test("AppImage$")) | "\(.name) \(.digest)"'
   ```
3. Convert each digest to SRI format and paste it into `sources` in `package.nix`:
   ```sh
   nix hash convert --hash-algo sha256 --to sri <hex-digest>
   ```
4. Build to check it: `nix build && ./result/bin/opennow`

## Notes

- The package wraps the upstream AppImage with `appimageTools.wrapType2`. It does not build OpenNOW from source.
- VA-API, VDPAU, PipeWire and PulseAudio libraries are included in the FHS environment for hardware video decoding and audio. Hardware decoding also needs `hardware.graphics.enable = true;` (it is on by default on most desktop setups).
- The `opennow://` URL handler from upstream's desktop entry is installed too.
