{ 
  config,
  lib,
  ... 
}:
  # Bring in color definitions from stylix
  let 
    colors = config.lib.stylix.colors.withHashtag;
  in
{
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[](${colors.base02})$username"
        "[](bg:${colors.base0A} fg:${colors.base02})"
        "$hostname$nix_shell"
        "[](bg:${colors.base0D} fg:${colors.base0A})"
        "$directory"
        "[](bg:${colors.base08} fg:${colors.base0D})"
        "$git_branch$git_status"
        "[](bg:${colors.base02} fg:${colors.base08})"
        "$time"
        "[](${colors.base02})"
        "$line_break"
        "$character"
      ];
      right_format = "$cmd_duration";
      username = {
        style_user = "bg:${colors.base02} fg:${colors.base05} bold";
        style_root = "bg:${colors.base02} fg:${colors.base08} bold";
        show_always = true;
        format = "[ $user ]($style)";
      };
      hostname = {
        ssh_only = true;
        style = "bg:${colors.base0E} fg:${colors.base00}";
        format = "($style)[ $hostname ]($style)";
      };
      nix_shell = {
        style = "bg:${colors.base0E} fg:${colors.base00}";
        format = "[ nix-shell ]($style)";
      };
      directory = {
        style = "bg:${colors.base0D} fg:${colors.base00}";
        format = "[ $path ]($style)";
      };
      git_branch = {
        style = "bg:${colors.base08} fg:${colors.base00}";
        format = "[ $symbol$branch ]($style)";
      };
      git_status = {
        style = "bg:${colors.base08} fg:${colors.base00}";
        format = "[($all_status$ahead_behind )]($style)";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:${colors.base02} fg:${colors.base05} bold";
        format = "[  $time ]($style)";
      };
      cmd_duration = {
        style = "fg:${colors.base0A} bold";
        format = "[  took $duration]($style)";
      };

    };
  };
}