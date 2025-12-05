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

  guestConfig = vmName: cfg.guests.${vmName};

  pkvmGuestModule = vmCfg: {
    boot.kernelPackages = pkgs.linuxPackagesFor vmCfg.kernelPackage;

    microvm = {
      hypervisor = vmCfg.vmm;

      crosvm.extraArgs = [
        "--protected-vm-without-firmware"
      ];

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

  # The guests are protected VMs by default, but it is possible to opt-out
  # by setting pkvm.<vm>.enableConfig = false.
  isConfigEnabled = vmName: cfg.enable && (guestConfig vmName).enableConfig;
in
{
  options.ghaf.virtualization.pkvm = {
    enable = lib.mkOption {
      description = "Enable pKVM hypervisor";
      type = lib.types.bool;
      default = false;
    };

    hostKernelPackage = lib.mkOption {
      description = "Kernel package for the host";
      type = lib.types.package;
      default = pkgs.linux-pkvm-x86;
    };

    hostKernelParams = lib.mkOption {
      description = "Additional kernel parameters for the host";
      type = lib.types.listOf lib.types.str;
      default = [
        "kvm-intel.pkvm=1"
        "intel_iommu=sm_on"
        # FIXME: DEBUGGING
        "earlyprintk=ttyS0"
        "ignore_loglevel"
        "console=ttyS0"
      ];
    };

    guests = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enableConfig = lib.mkOption {
              description = "Enable guest VM configuration";
              type = lib.types.bool;
              default = true;
            };

            vmm = lib.mkOption {
              description = "Hypervisor option passed to microvm.";
              type = lib.types.enum [
                "qemu"
                "crosvm"
              ];
              default = "qemu";
            };

            kernelPackage = lib.mkOption {
              description = "Kernel package for the guest VM.";
              type = lib.types.package;
              default = pkgs.linux-pkvm-x86-guest;
            };
          };
        }
      );
      description = "pKVM settings for individual guest VMs";
      default = { };
    };
  };

  config = lib.mkMerge [
    {
      ghaf.virtualization.pkvm.guests = lib.genAttrs (lib.attrNames allVms) (_vmName: { });
    }
    (lib.mkIf cfg.enable {
      boot.kernelPackages = pkgs.linuxPackagesFor cfg.hostKernelPackage;
      boot.kernelParams = lib.mkAfter cfg.hostKernelParams;
    })
    {
      ghaf.virtualization.microvm = lib.mapAttrs (
        vmName: _vmCfg:
        lib.optionalAttrs (isConfigEnabled vmName) {
          extraModules = lib.mkAfter [
            (pkvmGuestModule (guestConfig vmName))
          ];
        }
      ) allVms;
    }
  ];
}
