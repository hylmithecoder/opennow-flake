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

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.opennow;
        in {
          options.programs.opennow = {
            enable = lib.mkEnableOption "OpenNOW, an open-source GeForce NOW client";
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.callPackage ./package.nix { };
              defaultText = lib.literalExpression "opennow-flake's package";
              description = "The OpenNOW package to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };
    };
}
