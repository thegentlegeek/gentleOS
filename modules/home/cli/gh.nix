{
  lib,
  ...
}:

{
  # GitHub CLI. Settings are declarative (config.yml); the login token is
  # per-machine state gh keeps outside it (hosts.yml or the keyring), so after
  # a fresh install run `gh auth login` once.
  programs.gh.enable = lib.mkDefault true;
}
