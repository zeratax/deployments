{ config, pkgs, ... }:

{
    security.acme.defaults.email = "cert@zera.tax";
    security.acme.acceptTerms = true;
}
