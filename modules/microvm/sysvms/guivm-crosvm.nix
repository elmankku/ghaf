# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# GUI VM settings specific to the Crosvm VMM.
#
{ config, lib, ... }:
{
  _file = ./guivm-crosvm.nix;

  boot.kernelParams = lib.mkAfter (
    lib.optionals (config.microvm.hypervisor == "crosvm") [
      # This is needed when using viommu with both KVM and pKVM
      "i915.enable_psr2_sel_fetch=0"
      # This is needed when using viommu with KVM
      "i915.enable_guc=2"
    ]
  );
}
