{ 
  pkgs,
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    bitwarden-cli
    bws  # bitwarden secrets manager LEARN THIS!
    rbw
    pinentry-rofi
    pinentry-tty
  ];
}