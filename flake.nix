{
  description = "OpenNOW - open-source GeForce NOW client (Qt AppImage)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        opennow = pkgs.callPackage ./package.nix { };
        default = opennow;
      });

      apps = forAllSystems (pkgs: rec {
        opennow = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.opennow}/bin/opennow";
        };
        default = opennow;
      });

      overlays.default = final: prev: {
        opennow = final.callPackage ./package.nix { };
      };

      nixosModules.default = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        environment.systemPackages = [ pkgs.opennow ];
      };
    };
}
