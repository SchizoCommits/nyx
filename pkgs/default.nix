{
  self,
  inputs,
  ...
}: {
  systems = ["x86_64-linux"];

  perSystem = {pkgs, ...}: {
    packages = {
      nixos-plymouth = pkgs.callPackage ./plymouth-themes.nix {};
      fastfetch = pkgs.callPackage ./fastfetch.nix {};
      ani-cli = pkgs.callPackage ./ani-cli.nix {};
      mov-cli = pkgs.callPackage ./mov-cli.nix {};
      anime4k = pkgs.callPackage ./anime4k.nix {};
      spotify-wrapped = pkgs.callPackage ./spotify-wrapped.nix {};
      cloneit = pkgs.callPackage ./cloneit.nix {};
      discordo = pkgs.callPackage ./discordo.nix {};
      nicksfetch = pkgs.callPackage ./nicksfetch.nix {};
      rofi-calc-wayland = pkgs.callPackage ./rofi-calc-wayland.nix {};
      rofi-emoji-wayland = pkgs.callPackage ./rofi-emoji-wayland.nix {};
      wl-clip-persist = pkgs.callPackage ./wl-clip-persist.nix {};
      rat = pkgs.callPackage ./rat.nix {};
    };
  };
}
