{
  nixpkgs,
  inputs,
  ...
}: let
  inherit (nixpkgs) lib;

  builders = import ./builders.nix {inherit inputs lib;};
  services = import ./services.nix {inherit lib;};
  validators = import ./validators.nix {inherit lib;};
  helpers = import ./helpers.nix {inherit lib;};
in
  nixpkgs.lib.extend (_: _: builders // services // validators // helpers)
