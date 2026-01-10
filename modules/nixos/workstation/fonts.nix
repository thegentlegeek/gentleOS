{
  pkgs,
  ...
}:

{
  # Fonts
  fonts.packages = with pkgs; [
    libertine
    liberation_ttf
    source-sans-pro
    source-serif-pro
    source-code-pro
    scribus
    font-awesome
  ];
}
