# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; 

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  networking = {
    hostName = "bounce";
    domain = "int.leonardobishop.com";
    useNetworkd = true;
  };

  systemd.network = {
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = true;
    };

    netdevs."50-wg" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        MTUBytes = "1420";
      };

      wireguardConfig = {
        PrivateKeyFile = "/etc/wireguard-keys/private";
        ListenPort = 51820;
        RouteTable = "off";
      };

      wireguardPeers = [
        { # bongo
          PublicKey = "O6tY0fRWry7lR1sc549KwGTnYgn4TGRxweu8SzfNS1Y=";
          AllowedIPs = [ 
            "10.42.0.2/32"
            "0.0.0.0/0"
          ];
        }
        { # gchq-surveillance-van
          PublicKey = "jZcbtTxYZ1AIcLKyDmZdkgu4DShYKEow3gMft9xDKyQ=";
          AllowedIPs = [ "10.42.0.3/32" ];
        }
        { # iPhone
          PublicKey = "d0tIM/Y2SjGTtKq3ua/YWrzStnZzdaY52PT/Z6yF7U0=";
          AllowedIPs = [ "10.42.0.4/32" ];
        }
        { # eris
          PublicKey = "yNlgW5w8WHMJ+mX9tsv64Y5RE2tj9VvC8gdKgsy7F18=";
          AllowedIPs = [ "10.42.0.5/32" ];
        }
        { # corvette
          PublicKey = "N4OKlcIS4fCeFeIaZIugGN/SW01PSaVt6/hc+wt/tnc=";
          AllowedIPs = [ "10.42.0.6/32" ];
        }
      ];
    };

    networks.wg0 = {
      matchConfig.Name = "wg0";
      networkConfig.DHCP = false;
      address = [ "10.42.0.1/16" ];
    };
  };

  systemd.services.sshd = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  systemd.services.wg-bongo-routing = {
    enable = true;
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    description = "Add routing table entries for bongo forward proxy";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = [
        "${pkgs.iproute2}/bin/ip rule add from 10.42.0.3 table 100"
        "${pkgs.iproute2}/bin/ip rule add from 10.42.0.4 table 100"
        "${pkgs.iproute2}/bin/ip route add 0.0.0.0/0 dev wg0 table 100"
      ];
      ExecStop = [
        "${pkgs.iproute2}/bin/ip rule del from 10.42.0.3 table 100"
        "${pkgs.iproute2}/bin/ip rule del from 10.42.0.4 table 100"
        "${pkgs.iproute2}/bin/ip route del 0.0.0.0/0 dev wg0 table 100"
      ];
    };
  };

  networking.firewall = {
    checkReversePath = false; 
    interfaces.enp1s0 = {
      allowedUDPPorts = [ 51820 ];
    };
    interfaces.wg0 = {
      allowedTCPPorts = [ 22 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      ListenAddress = "10.42.0.1:22";
    };
  };

  services.resolved = {
    enable = false;
  };

  services.coredns = {
    enable = true;
    config = ''
      . {
        hosts {
          10.42.0.1 bounce.int.leonardobishop.com
          10.42.0.2 bongo.int.leonardobishop.com
          10.42.0.2 vault.int.leonardobishop.com
          10.42.0.2 cloud.int.leonardobishop.com
          10.42.0.2 media.int.leonardobishop.com
          10.42.0.5 eris.int.leonardobishop.com
          fallthrough
        }
        forward . 9.9.9.9 149.112.112.112
        errors
      }
    '';
  };

  programs.tcpdump.enable = true;

  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyCwcyijBVmxn8IuXVAtbP/rXFeHDOiHy5wKl3iaaHf leonardo@gchq-surveillance-van"
  ];

  time.timeZone = "Europe/Helsinki";

  environment.systemPackages = with pkgs; [
    vim
    dig
    wireguard-tools
  ];


  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

