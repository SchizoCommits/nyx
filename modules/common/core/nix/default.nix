{
  config,
  pkgs,
  lib,
  inputs,
  inputs',
  self,
  ...
}:
with lib; {
  imports = [
    ./builders.nix # import builders config
  ];

  system = {
    autoUpgrade.enable = false;
    stateVersion = lib.mkDefault "23.05";
  };

  environment = {
    etc = with inputs; {
      # set channels (backwards compatibility)
      "nix/flake-channels/system".source = self;
      "nix/flake-channels/nixpkgs".source = nixpkgs;
      "nix/flake-channels/home-manager".source = home-manager;

      # preserve current flake in /etc
      "nixos/flake".source = self;
    };

    # we need git for flakes, don't we
    systemPackages = [pkgs.git];
  };

  nixpkgs = {
    pkgs = self.legacyPackages.${config.nixpkgs.system};

    config = {
      allowUnfree = true; # really a pain in the ass to deal with when disabled
      allowBroken = false;
      allowUnsupportedSystem = true;
      permittedInsecurePackages = []; # default to none, add more as necessary
    };

    overlays = [
      inputs.rust-overlay.overlays.default

      (self: super: {
        nixSuper = inputs'.nix-super.packages.default;
      })
    ];
  };

  # faster rebuilding
  documentation = {
    doc.enable = false;
    nixos.enable = false;
    info.enable = false;
    man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkDefault true;
    };
  };

  nix = let
    mappedRegistry = mapAttrs (_: v: {flake = v;}) inputs;
  in {
    package = pkgs.nixSuper; # pkgs.nixVersions.unstable;

    # pin the registry to avoid downloading and evaluating a new nixpkgs
    # version everytime
    # this will add each flake input as a registry
    # to make nix3 commands consistent with your flake
    registry = mappedRegistry // {default = mappedRegistry.nixpkgs;};

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    # Make builds run with low priority so my system stays responsive
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;

    # set up garbage collection to run daily,
    # removing unused packages after three days
    gc = {
      automatic = true;
      dates = "Mon *-*-* 03:00";
      options = "--delete-older-than 3d";
    };

    # automatically optimize nix store my removing hard links
    # do it after the gc
    optimise = {
      automatic = true;
      dates = ["04:00"];
    };

    settings = {
      # specify the path to the nix registry
      flake-registry = "/etc/nix/registry.json";
      # Free up to 10GiB whenever there is less than 5GB left.
      # this setting is in bytes, so we multiply with 1024 thrice
      min-free = "${toString (5 * 1024 * 1024 * 1024)}";
      max-free = "${toString (10 * 1024 * 1024 * 1024)}";
      # automatically optimise symlinks
      auto-optimise-store = true;
      # allow sudo users to mark the following values as trusted
      allowed-users = ["@wheel" "nix-builder"];
      # only allow sudo users to manage the nix store
      trusted-users = ["@wheel" "nix-builder"];
      # let the system decide the number of max jobs
      max-jobs = "auto";
      # build inside sandboxed environments
      sandbox = true;
      # supported system features
      # TODO: "gccarch-core2" "gccarch-haswell"
      system-features = ["nixos-tests" "kvm" "recursive-nix" "big-parallel"];
      # extra architectures supported by my builders
      extra-platforms = config.boot.binfmt.emulatedSystems;
      # continue building derivations if one fails
      keep-going = true;
      # show more log lines for failed builds
      log-lines = 30;
      # enable new nix command and flakes
      # and also "unintended" recursion as well as content addresssed nix
      extra-experimental-features = [
        "flakes"
        "nix-command"
        "recursive-nix"
        "ca-derivations"
        "repl-flake"
        "auto-allocate-uids"
      ];
      # don't warn me that my git tree is dirty, I know
      warn-dirty = false;
      # maximum number of parallel TCP connections used to fetch imports and binary caches, 0 means no limit
      http-connections = 50;
      # whether to accept nix configuration from a flake without prompting
      accept-flake-config = true;

      # for direnv GC roots
      keep-derivations = true;
      keep-outputs = true;

      # use binary cache, its not gentoo
      # external builders can also pick up those substituters
      builders-use-substitutes = true;
      # substituters to use
      substituters = [
        "https://cache.ngi0.nixos.org" # content addressed nix cache (TODO)
        "https://cache.nixos.org" # funny binary cache
        "https://cache.privatevoid.net" # for nix-super
        "https://nixpkgs-wayland.cachix.org" # automated builds of *some* wayland packages
        "https://nix-community.cachix.org" # nix-community cache
        "https://hyprland.cachix.org" # hyprland
        "https://nix-gaming.cachix.org" # nix-gaming
        "https://nixpkgs-unfree.cachix.org" # unfree-package cache
        "https://numtide.cachix.org" # another unfree package cache
        "https://helix.cachix.org" # helix
        "https://anyrun.cachix.org" # anyrun
        "https://notashelf.cachix.org" # cached stuff from my flake outputs
        "https://neovim-flake.cachix.org" # a cache for my neovim flake
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
        "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        "notashelf.cachix.org-1:VTTBFNQWbfyLuRzgm2I7AWSDJdqAa11ytLXHBhrprZk="
        "neovim-flake.cachix.org-1:iyQ6lHFhnB5UkVpxhQqLJbneWBTzM8LBYOFPLNH4qZw="
      ];
    };
  };
}
