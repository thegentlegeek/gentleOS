{ 
  pkgs,
  ... 
}:

{
  programs.rbw = {
    enable = true;
    settings =
    ''{
      email = justin@geigley.com;
      pinentry = ${pkgs.pinentry-tty}/bin/pinentry-tty;
    }'';
  };
}