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
    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          inputs.zig-flake.packages.${system}.default
          inputs.zls.packages.${system}.default

          libGL

          # X11 dependencies
          libx11
          libx11.dev
          libxcursor
          libxi
          libxinerama
          libxrandr
        ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
