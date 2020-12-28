{ config, pkgs, ... }:

{
    security.acme.email = "cert@zera.tax";
    security.acme.acceptTerms = true;
}
