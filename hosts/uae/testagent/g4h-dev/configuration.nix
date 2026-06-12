# SPDX-FileCopyrightText: 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  lib,
  config,
  ...
}:
{
  imports = [
    ../agents-common.nix
    ./disk-config.nix
  ]
  ++ (with self.nixosModules; [
    user-eyad
    team-testers
  ]);

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      let
        credentialSecrets = [
          "dut-pass"
          "plug-login"
          "plug-pass"
          "switch-token"
          "switch-secret"
          "wifi-ssid"
          "wifi-password"
          "pi-login"
          "pi-pass"
        ];
      in
      lib.genAttrs credentialSecrets (_: {
        sopsFile = lib.mkForce ./credentials.yaml;
      });
  };

  networking.hostName = "g4h-testagent-dev";
  services.testagent = {
    variant = "dev";
    hardware = [ "orin-nx" ];
  };

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-intel"
      "sg"
    ];
  };

  services.logind.lidSwitch = "ignore";

  services.udev.extraRules = ''
    # Orin NX
    SUBSYSTEM=="tty", ENV{ID_PATH}=="pci-0000:00:14.0-usb-0:1.3.1:1.0", ENV{ID_VENDOR_ID}=="067b", ENV{ID_MODEL_ID}=="2303", SYMLINK+="ttyORINNX1", MODE="0666", GROUP="dialout"

    # SSD-drive
    SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_SERIAL_SHORT}=="323535303432343030313539", SYMLINK+="ssdORINNX1", MODE="0666", GROUP="dialout"
  '';

  environment.etc."jenkins/test_config.json".text =
    let
      location = config.networking.hostName;
    in
    builtins.toJSON {
      addresses = {
        relay_serial_port = "/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_BG03IPGA-if00-port0";
        OrinNX1 = {
          inherit location;
          device_id = "00-31-60-10-98";
          netvm_hostname = "ghaf-0828379288";
          serial_port = "/dev/ttyORINNX1";
          relay_number = 1;
          device_ip_address = "10.44.0.21";
          socket_ip_address = "NONE";
          plug_type = "NONE";
          switch_bot = "NONE";
          usbhub_serial = "8E25534A";
          ext_drive_by-id = "/dev/ssdORINNX1";
          threads = 8;
        };
      };
    };

  system.stateVersion = lib.mkForce "25.11";
}
