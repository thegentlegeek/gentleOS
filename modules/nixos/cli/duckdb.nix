{ 
  pkgs,
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    duckdb
  ];
}