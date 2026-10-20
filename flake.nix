{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

    zig-flake = {
      url = "github:silversquirl/zig-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls";
      inputs = {
        zig-flake.follows = "zig-flake";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs: {
    devShells = builtins.mapAttrs (
      system: pkgs:
      let
        dependencies = with pkgs; [
          libGL

          # X11 dependencies
          libx11
          libx11.dev
          libxcursor
          libxi
          libxinerama
          libxrandr
        ];
      in
      {
        default = pkgs.mkShell {
          packages = [
            inputs.zig-flake.packages.${system}.default
            inputs.zls.packages.${system}.default
          ]
          ++ dependencies;
        };

        minimal = pkgs.mkShell {
          packages = dependencies;
        };
      }
    ) inputs.nixpkgs.legacyPackages;
  };
}
