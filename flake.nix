{
  description = "A utility library for creating and managing Nix modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    lib = import ./lib { lib = nixpkgs.lib; libCustom = self.lib; };
  };
}
