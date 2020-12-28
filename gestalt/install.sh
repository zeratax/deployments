#! /bin/sh

set -e
set -u
set -x

# configure this!
hostname="gestalt"
password=""
diskdev=/dev/sda
bootpart=/dev/sda1
rootpart=/dev/sda2

sgdisk -o -g -n 1::+550M -t 1:ef00 -n 2:: -t 2:8300 $diskdev

echo "$password" | cryptsetup luksFormat $rootpart
echo "$password" | cryptsetup luksOpen $rootpart enc-pv

pvcreate /dev/mapper/enc-pv
vgcreate vg /dev/mapper/enc-pv
lvcreate -L 16G -n swap vg
lvcreate -l '100%FREE' -n root vg

mkfs.fat $bootpart
mkfs.btrfs -L root /dev/vg/root
mkswap -L swap /dev/vg/swap

mount /dev/vg/root /mnt
pushd /mnt
btrfs subvolume create @
btrfs subvolume create @home
popd
umount /mnt

mount /dev/vg/root /mnt -o subvol=@,discard,ssd,compress=lzo,autodefrag
mkdir -p /mnt/{home,boot}
mount /dev/vg/root /mnt/home -o subvol=@home,discard,ssd,compress=lzo,autodefrag
mount $bootpart /mnt/boot  
swapon /dev/vg/swap

nixos-generate-config --root /mnt

for uuid in /dev/disk/by-uuid/*
do
	if test $(readlink -f $uuid) = $rootpart
	then
		luksuuid=$uuid
		break
	fi
done

cat << EOF > /mnt/etc/nixos/configuration.nix
   {
        imports =
        [ # Include the results of the hardware scan.
          ./hardware-configuration.nix
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.initrd.kernelModules = [ "dm-snapshot" ];
        boot.initrd.luks.devices = [
                { 
                  name = "enc-pv";
                  device = "$luksuuid";
                }
        ];
        boot.cleanTmpDir = true;
        boot.kernelModules = [ "dm-snapshot" ];

        nixpkgs.config.allowUnfree = true;
        networking.hostName = "nixos";
        time.timeZone = "NZ";

        environment.systemPackages = with pkgs; [
            curl
            firefox
            gcc
            git
            ntfs3g
            python2
            python3
        ];

        services.openssh.enable = true;
        services.openssh.passwordAuthentication = false;

        services.xserver.enable = true;
        services.xserver.windowManager.i3.enable = true;

        services.cron.mailto = "root";

        # This value determines the NixOS release with which your system is to be
        # compatible, in order to avoid breaking some software such as database
        # servers. You should change this only after NixOS release notes say you
        # should.
        system.stateVersion = "20.03"; # Did you read the comment?
    }
EOF

