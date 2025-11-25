# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  pkgs,
  buildLinux,
  isGuest ? false,
  argsOverride ? { },
  ...
}:
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
  kernelVersion = "6.12.58";
  version = "${kernelVersion}-pkvm-${variant}";

  pkvmKernel = buildLinux (
    {
      inherit version;
      modDirVersion = kernelVersion;

      src = pkgs.fetchFromGitHub {
        owner = "tiiuae";
        repo = "pKVM-x86";
        rev = "50b5d7c5decca0ff4d935fe6f59c326d351ebfda";
        sha256 = "sha256-bFtWVV1Qor/HDTet52c2zp7OeWV7RuewufL52GEaBmI=";
      };
      structuredExtraConfig = variants.${variant};

      extraMeta = {
        platforms = with lib.platforms; lib.intersectLists x86 linux;
      };
    }
    // argsOverride
  );
in
pkvmKernel
