{
  config,
  lib,
  ...
}:
with lib; {
  imports = [
    ./ssh.nix
    ./blocker.nix
    ./tailscale.nix
  ];

  services = {
    # systemd DNS resolver daemon
    resolved.enable = true;
  };

  networking = {
    # generate a host ID by hasing the hostname
    hostId = builtins.substring 0 8 (
      builtins.hashString "md5" config.networking.hostName
    );

    # global dhcp has been deprecated upstream
    # use networkd instead
    # individual interfaces are still managed through dhcp in hardware configurations
    useDHCP = mkDefault false;
    useNetworkd = mkDefault true;

    # dns
    nameservers = [
      # cloudflare, yuck
      # shares data
      "1.1.1.1"
      "1.0.0.1"

      # quad9, said to be the best
      # shares *less* data
      "9.9.9.9"

      # TODO: find a schizo nameserver that does not compromise on speed or availability
    ];

    networkmanager = {
      enable = true;
      plugins = []; # disable all plugins, we don't need them
      dns = "systemd-resolved"; # use systemd-resolved as dns backend
      unmanaged = ["docker0" "rndis0"];
      wifi = {
        macAddress = "random"; # use a random mac address on every boot
        powersave = true; # enable wifi powersaving
      };
    };
  };

  # enable wireless database, it helps with finding the right channels
  hardware.wirelessRegulatoryDatabase = true;

  # allow for the system to boot without waiting for the network interfaces are online
  # speeds up boot times
  systemd = let
    ethernetDevices = [
      "wlp1s0f0u8" # wifi dongle
    ];
  in {
    network.wait-online.enable = false;
    services =
      {
        NetworkManager-wait-online.enable = false;

        # disable networkd and resolved from being restarted on configuration changes
        systemd-networkd.stopIfChanged = false;
        systemd-resolved.stopIfChanged = false;
      }
      // lib.concatMapAttrs (_: v: v) (lib.genAttrs ethernetDevices (device: {
        # Assign an IP address when the device is plugged in rather than on startup. Needed to prevent
        # blocking the boot sequence when the device is unavailable, as it is hotpluggable.
        "network-addresses-${device}".wantedBy = lib.mkForce ["sys-subsystem-net-devices-${device}.device"];
      }));
  };
}
