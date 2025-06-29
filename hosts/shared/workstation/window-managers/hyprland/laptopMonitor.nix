{
  pkgs,
  ...
}:

{
  ## BEGIN - laptop display only enabled when not connected to external display

  # Declare the monitorSwitch service with NixOS environment wrapping
  systemd.services.monitorSwitch = {
    description = "Monitor switch script to manage displays";
    after = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];

    # Wrap the script execution in a NixOS environment
    script = ''
      #!/bin/bash
      external_monitor_connected=$(hyprctl monitors | grep -E 'DP|HDMI')

      if [ "$external_monitor_connected" != "" ]; then
          hyprctl dispatch dpms off eDP-1
      else
          hyprctl dispatch dpms on eDP-1
      fi
    '';

    # Use the full Nix environment where hyprctl is available
    path = [ pkgs.hyprland pkgs.bash ];

    serviceConfig = {
      Restart = "on-failure";
    };
  };

  # Declare the udev rule for monitor connection/disconnection
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "monitor_switch_udev";
      text = ''
        ACTION=="change", SUBSYSTEM=="drm", RUN+="${pkgs.hyprland}/bin/hyprctl dispatch dpms off eDP-1"
      '';
      destination = "/etc/udev/rules.d/95-monitor-switch.rules";
    })
  ];

  ## END
}
