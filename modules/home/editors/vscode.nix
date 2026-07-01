{
  pkgs,
  ...
}:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = false;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions;
        [
          jnoortheen.nix-ide
          gruntfuggly.todo-tree
          mechatroner.rainbow-csv
        ];
      userSettings = {
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "editor.inlineSuggest.enabled" = true;

        "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";

        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.alejandra}/bin/alejandra";
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "nix.serverSettings"."nil"."formatting"."command" = ["${pkgs.alejandra}/bin/alejandra"];
      };
    };
  };
}
