{ claudeCodePackage, claudeDesktopPackage }:

{
  pkgs,
  ...
}:

{
  # Claude Code CLI. Leave `settings` unset so ~/.claude/settings.json stays
  # writable by Claude Code itself (setting it makes the file a read-only symlink).
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;
  };

  home.packages = [
    claudeDesktopPackage
    pkgs.qemu_kvm # Claude Desktop's Cowork VMs use qemu from the host PATH
  ];
}
