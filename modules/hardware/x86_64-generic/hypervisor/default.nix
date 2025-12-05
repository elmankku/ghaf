# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  cfg = config.ghaf.virtualization.pkvm;
  allVms = lib.filterAttrs (_name: vmCfg: vmCfg ? extraModules) options.ghaf.virtualization.microvm;

  pkvmGuestModule = {
    boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-pkvm-x86-guest;

    microvm = {
      hypervisor = "qemu";

      qemu = {
        machine = "q35";

        machineOpts = {
          kernel-irqchip = "split";
          confidential-guest-support = "pkvm0";
        };

        extraArgs = lib.mkAfter [
          "-object"
          "pkvm-guest,id=pkvm0"
          "-bios"
          "${pkgs.qboot-pkvm}/bios.bin"
          "-overcommit"
          "mem-lock=on"
        ];
      };
    };
  };

  # The guests are protected VMs by default, but it is possible to opt-out of
  # the default configuration by setting pkvm.<vm>.protectedGuest = false.
  isProtectedGuest = vmName: cfg.enable && (cfg.guests.${vmName}.protectedGuest or true);
in
{
  options.ghaf.virtualization.pkvm = {
    enable = lib.mkOption {
      description = "Enable pKVM hypervisor";
      type = lib.types.bool;
      default = false;
    };

    guests = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            protectedGuest = lib.mkOption {
              description = "Controls whether this guest is a pKVM protected VM.";
              type = lib.types.bool;
              default = true;
            };
          };
        }
      );
      description = "pKVM settings for individual guest VMs";
      default = { };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-pkvm-x86;
      boot.kernelParams = lib.mkAfter [
        "kvm-intel.pkvm=1"
        "intel_iommu=sm_on"
        # FIXME: DEBUGGING
        "earlyprintk=ttyS0"
        "ignore_loglevel"
        "console=ttyS0"
      ];
    })
    {
      ghaf.virtualization.microvm = lib.mapAttrs (
        vmName: _vmCfg:
        lib.optionalAttrs (isProtectedGuest vmName) {
          extraModules = lib.mkAfter [
            pkvmGuestModule
          ];
        }
      ) allVms;
    }
  ];
}
