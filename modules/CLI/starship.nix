{ 
  config,
  lib,
  ... 
}:
  # Bring in color definitions from stylix
  let 
    stylix00 = config.myColors.stylix00;
    stylix01 = config.myColors.stylix01;
    stylix02 = config.myColors.stylix02;
    stylix03 = config.myColors.stylix03;
    stylix04 = config.myColors.stylix04;
    stylix05 = config.myColors.stylix05;
    stylix06 = config.myColors.stylix06;
    stylix07 = config.myColors.stylix07;
    stylix08 = config.myColors.stylix08;
    stylix09 = config.myColors.stylix09;
    stylix0A = config.myColors.stylix0A;
    stylix0B = config.myColors.stylix0B;
    stylix0C = config.myColors.stylix0C;
    stylix0D = config.myColors.stylix0D;
    stylix0E = config.myColors.stylix0E;
    stylix0F = config.myColors.stylix0F;
  in
{
  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "[](${stylix02})$username"
        "[](bg:${stylix0A} fg:${stylix02})"
        "$hostname$nix_shell"
        "[](bg:${stylix0D} fg:${stylix0A})"
        "$directory"
        "[](bg:${stylix08} fg:${stylix0D})"
        "$git_branch$git_status"
        "[](bg:${stylix02} fg:${stylix08})"
        "$time"
        "[](${stylix02})"
        "$line_break"
        "$character"
      ];
      right_format = "$cmd_duration";
      username = {
        style_user = "bg:${stylix02} fg:${stylix05} bold";
        style_root = "bg:${stylix02} fg:${stylix08} bold";
        show_always = true;
        format = "[ $user ]($style)";
      };
      hostname = {
        ssh_only = true;
        style = "bg:${stylix0E} fg:${stylix00}";
        format = "($style)[ $hostname ]($style)";
      };
      nix_shell = {
        style = "bg:${stylix0E} fg:${stylix00}";
        format = "[ nix-shell ]($style)";
      };
      directory = {
        style = "bg:${stylix0D} fg:${stylix00}";
        format = "[ $path ]($style)";
      };
      git_branch = {
        style = "bg:${stylix08} fg:${stylix00}";
        format = "[ $symbol$branch ]($style)";
      };
      git_status = {
        style = "bg:${stylix08} fg:${stylix00}";
        format = "[($all_status$ahead_behind )]($style)";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:${stylix02} fg:${stylix05} bold";
        format = "[  $time ]($style)";
      };
      cmd_duration = {
        style = "fg:${stylix0A} bold";
        format = "[  took $duration]($style)";
      };

    };
  };
}