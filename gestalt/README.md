# setup

## first install
create a basic system by booting into a NixOS live cd and editing and running
```console
# ./install.sh
```

## required channels
After a successfull install we want these or newer channels:
 - nixos https://nixos.org/channels/nixos-23.05
 - nixos-hardware https://github.com/NixOS/nixos-hardware/archive/master.tar.gz
 - nixos-unstable https://nixos.org/channels/nixos-unstable

## rebuild system
Then we can copy the [configuration.nix](./configuration.nix) and rebuild our system
```console
# nixos-rebuild switch
```

## setup user
Now we just need to set a password for our user
```console
# passwd kaine
```

And log into kaine
Now we can setup our user see https://github.com/zeratax/dotfiles

For convenience we can clone this repo to our main user and link the configuration to this repo
```
$ mkdir -p git
$ cd git
$ git clone git@github.com/ZerataX/deployements
$ ln -sf /home/kaine/git/deployments/gestalt/configuration.nix /etc/nixos/configuration.nix
```
