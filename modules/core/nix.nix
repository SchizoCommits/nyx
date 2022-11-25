{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  environment = {
    defaultPackages = [];
    etc = {
      "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
      "nix/flake-channels/home-manager".source = inputs.home-manager;
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
  };

  # faster rebuilding
  documentation = {
    enable = false;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
  };

  nix = {
    package = pkgs.nixUnstable;

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 4d";
    };

    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      experimental-features = recursive-nix nix-command flakes
      keep-outputs = true
      keep-derivations = true
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
      accept-flake-config = true
      http-connections = 0
      warn-dirty = false
    '';
    settings = {
      auto-optimise-store = true;

      allowed-users = [
        "root"
        "@wheel"
      ];

      trusted-users = [
        "root"
        "@wheel"
      ];

      max-jobs = lib.mkDefault 6;
      # use binary cache, its not gentoo
      substituters = [
        "https://cache.nixos.org"
        "https://fortuneteller2k.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "fortuneteller2k.cachix.org-1:kXXNkMV5yheEQwT0I4XYh1MaCSz+qg72k8XAi2PthJI="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];

      sandbox = true;
      system-features = ["kvm" "recursive-nix" "big-parallel"];
    };
  };
  system.autoUpgrade.enable = false;
  system.stateVersion = "22.05"; # DONT TOUCH THIS
}
