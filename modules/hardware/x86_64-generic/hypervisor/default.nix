# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.virtualization.pkvm;
  # Enabled-only VM discovery to avoid touching disabled VMs.
  enabledSysVms = config.ghaf.virtualization.microvm.sysvm.enabledVms;
  enabledAppVms = config.ghaf.virtualization.microvm.appvm.enabledVms;
  allVms = lib.unique ((lib.attrNames enabledSysVms) ++ (lib.attrNames enabledAppVms));

  guestConfig = vmName: cfg.guests.${vmName};
  mkPkvmEvaluatedConfig =
    vmName: evaluatedConfig:
    evaluatedConfig.extendModules {
      modules = [ (pkvmGuestModule (guestConfig vmName)) ];
    };

  pkvmGuestModule = vmCfg: { config, ... }: {
    ghaf.virtualization.qemu = lib.mkIf (config.microvm.hypervisor == "qemu") {
      package = pkgs.pkvm-qemu;
    };

    boot.kernelPackages = pkgs.linuxPackagesFor (
      vmCfg.kernelPackage.override {
        argsOverride.kernelPatches = config.boot.kernelPatches;
      }
    );

    # Temporarily disable GPU suspend until its kernel patch is rebased.
    ghaf.services.power-manager.gui.gpuSuspend = lib.mkForce false;

    microvm = {
      crosvm = lib.mkIf (config.microvm.hypervisor == "crosvm") {
        extraArgs = [
          "--protected-vm-without-firmware"
        ];
        package = lib.mkForce cfg.crosvm.package;
      };

      qemu = lib.mkIf (config.microvm.hypervisor == "qemu") {
        machine = "q35";

        machineOpts = {
          kernel-irqchip = "split";
          confidential-guest-support = "pkvm0";
        };

        extraArgs = lib.mkAfter [
          "-object"
          "pkvm-guest,id=pkvm0"
          "-bios"
          "${pkgs.pkvm-qboot}/bios.bin"
          "-overcommit"
          "mem-lock=on"
        ];
      };
    };
  };

  # The guests are protected VMs by default, but it is possible to opt-out
  # by setting pkvm.<vm>.enableConfig = false.
  isConfigEnabled = vmName: cfg.enable && (guestConfig vmName).enableConfig;

  sysVmOverrides = lib.foldl' lib.recursiveUpdate { } (
    lib.mapAttrsToList (
      vmType: vmCfg:
      lib.optionalAttrs (isConfigEnabled vmType && vmCfg.evaluatedConfig != null) {
        "${vmCfg.vmName}" = {
          # We must use mkForce to ensure pKVM settings are applied
          evaluatedConfig = lib.mkForce (mkPkvmEvaluatedConfig vmType vmCfg.evaluatedConfig);
        };
      }
    ) enabledSysVms
  );

  appVmOverrides = lib.foldl' lib.recursiveUpdate { } (
    lib.mapAttrsToList (
      vmType: vmCfg:
      lib.optionalAttrs (isConfigEnabled vmType && vmCfg.evaluatedConfig != null) {
        "${vmCfg.name}-vm" = {
          # We must use mkForce to ensure pKVM settings are applied
          evaluatedConfig = lib.mkForce (mkPkvmEvaluatedConfig vmType vmCfg.evaluatedConfig);
        };
      }
    ) enabledAppVms
  );
in
{
  _file = ./default.nix;

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
      ];
    };

    crosvm.package = lib.mkOption {
      description = "The crosvm package used for pKVM guests.";
      type = lib.types.package;
      default = pkgs.pkvm-crosvm;
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
      ghaf.virtualization.pkvm.guests = lib.genAttrs allVms (_vmName: { });
    }
    (lib.mkIf cfg.enable {
      boot.kernelPackages = pkgs.linuxPackagesFor cfg.hostKernelPackage;
      boot.kernelParams = lib.mkAfter cfg.hostKernelParams;
    })
    {
      microvm.vms = lib.recursiveUpdate sysVmOverrides appVmOverrides;
    }
  ];
}
