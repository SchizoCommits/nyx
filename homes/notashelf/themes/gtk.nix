{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  device = osConfig.modules.device;

  acceptedTypes = ["laptop" "desktop" "hybrid" "lite"];
in {
  config = mkIf (builtins.elem device.type acceptedTypes) {
    xdg.systemDirs.data = let
      schema = pkgs.gsettings-desktop-schemas;
    in ["${schema}/share/gsettings-schemas/${schema.name}"];

    home = {
      packages = with pkgs; [
        glib # gsettings
        (catppuccin-gtk.override {
          size = "standard";
          accents = ["blue"];
          variant = "mocha";
          tweaks = ["normal"];
        })
        (catppuccin-papirus-folders.override {
          accent = "blue";
          flavor = "mocha";
        })
      ];

      sessionVariables = {
        # set GTK theme as specified by the catppuccin-gtk package
        GTK_THEME = "${config.gtk.theme.name}";

        # gtk applications should use filepickers specified by xdg
        GTK_USE_PORTAL = "1";
      };
    };

    gtk = {
      enable = true;

      theme = {
        name = "Catppuccin-Mocha-Standard-Blue-dark";
        package = pkgs.catppuccin-gtk.override {
          size = "standard";
          accents = ["blue"];
          variant = "mocha";
          tweaks = ["normal"];
        };
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          accent = "blue";
          flavor = "mocha";
        };
      };

      font = {
        name = "Lexend";
        size = 13;
      };

      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        extraConfig = ''
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle="hintslight"
          gtk-xft-rgba="rgb"
        '';
      };

      gtk3.extraConfig = {
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
        gtk-application-prefer-dark-theme = 1;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    # cursor theme
    home = {
      pointerCursor = {
        package = pkgs.catppuccin-cursors.mochaDark; #pkgs.bibata-cursors;
        name = "Catppuccin-Mocha-Dark-Cursors"; #"Bibata-Modern-Classic";
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    };

    i18n.inputMethod.enabled = "fcitx5";
    i18n.inputMethod.fcitx5.addons = with pkgs; [fcitx5-mozc];
  };
}
