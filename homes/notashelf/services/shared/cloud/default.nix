{
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  device = osConfig.modules.device;
  video = osConfig.modules.system.video;
  env = osConfig.modules.usrEnv;

  acceptedTypes = ["desktop" "laptop" "lite" "hybrid"];
in {
  config = mkIf ((builtins.elem device.type acceptedTypes) && (video.enable && env.isWayland)) {
    /*
    services = {
      nextcloud-client.enable = true;
      nextcloud-client.startInBackground = true;
    };
    */

    home.packages = [pkgs.nextcloud-client];

    systemd.user.services.nextcloud = lib.mkGraphicalService {
      Unit.Description = "Nextcloud client service";
      Service = {
        ExecStart = "${pkgs.nextcloud-client}/bin/nextcloud --background";
        Restart = "always";
        Slice = "background.slice";
      };
    };
  };
}
