# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  buildLinux,
  isGuest ? false,
  ...
}@args:
let
  variant = if isGuest then "guest" else "host";
  variants = with pkgs.lib.kernel; {
    guest = {
      HYPERVISOR_GUEST = yes;
      PKVM_GUEST = yes;
    };
    host = {
      KVM = yes;
      KVM_INTEL = yes;
      PKVM_INTEL = yes;
      PKVM_INTEL_VE_MMIO = yes;
      PKVM_INTEL_VE_EMULATION = yes;
      PKVM_INTEL_DEBUG = yes;
      PKVM_INTEL_FORCE_PROTECTED_VM = yes;
      PKVM_INTEL_PROTECTED_VM_COREDUMP = yes;
      KSM = pkgs.lib.mkForce no;
      IOMMU_DEFAULT_PASSTHROUGH = yes;
      INTEL_IOMMU = yes;
    };
  };
  kernelVersion = "6.12.87";
  version = "${kernelVersion}-pkvm-${variant}";

  pkvmKernel = buildLinux (
    {
      inherit version;
      modDirVersion = kernelVersion;

      src = pkgs.fetchFromGitHub {
        owner = "elmankku";
        repo = "pKVM-x86-IA";
        rev = "63c0ab2b9eaab1eb5c32a4451334dcda43845f52";
        sha256 = "sha256-MK+f750cxN4vcDM0vbvzL6zluI25JLgW9dGuEUHzv+E=";
      };
      structuredExtraConfig = variants.${variant};

      extraMeta = {
        platforms = with lib.platforms; lib.intersectLists x86 linux;
      };
      kernelPatches = [
        {
          name = "pci: probe hypervisor isolated functions";
          patch = ./0001-pci-Add-option-for-scanning-all-possible-PCI-functio.patch;
          structuredExtraConfig =
            with pkgs.lib.kernel;
            lib.optionalAttrs isGuest {
              PCI_PROBE_ISOLATED_FUNCTIONS = yes;
            };
        }
        {
          name = "pkvm: Intel GPU OpRegion quirks";
          patch = ./0002-pkvm-x86-Fix-unhandled-VE-exceptions.patch;
        }
        {
          name = "DEBUG: Intel GPU debug";
          patch = ./0001-DEBUG-trace-IOMMU-for-GPU.patch;
          structuredExtraConfig =
            with pkgs.lib.kernel;
            lib.optionalAttrs (isGuest == false) {
              IOMMU_DEBUGFS = yes;
              INTEL_IOMMU_DEBUGFS = yes;
            };
        }
        {
          name = "REMOVE ME: ptdev concurrency fixes";
          patch = ./0001-pkvm-x86-address-ptdev-concurrency-issues.patch;
        }
      ];
    }
    // args.argsOverride or { }
  );
in
pkvmKernel
