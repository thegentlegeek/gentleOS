# Couldn't figure this import stuff out. Modularization is left for another day I guess. - 01/29/2025
{
chromium = {
  enable = true;
  enablePlasmaBrowserIntegration = true;
  extensions = [
    "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    "mpdajninpobndbfcldcmbpnnbhibjmch" # SAML-Tracer
    ];
  extraOpts = {
    # Security/Privacy
    "BrowserSignin" = 0;
    "SyncDisabled" = true;
    "PasswordManagerEnabled" = false;
    # QoL
    "HomepageIsNewTabPage" = true;
    "RestoreOnStartup" = 1;
    "ScreenCaptureAllowed" = true;
    "DeviceSecondFactorAuthentication" = true;
  };
};
}