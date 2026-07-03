# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  crosvm,
  ...
}:
crosvm.overrideAttrs (
  _finalAttrs: oldAttrs: {
    patches = oldAttrs.patches ++ [
      ./0001-crosvm-FIXME-always-trap-MSI-X-region.patch
      ./0001-vhost-user-handle-ACCESS_PLATFORM-for-protected-gues.patch
      ./0001-pci-handle-Intel-GPU-OpRegion-access.patch
      ./0002-evdev-allow-empty-unique-identifier.patch
      ./0003-WIP-input-hotplug.patch
      ./0004-DEBUG-GPU-ACPI-errors.patch
      ./0005-WIP-Fix-intel-DSM-size.patch
      ./0006-WIP-More-Intel-GPU-debug.patch
      ./0007-WIP-shadow-and-log-Intel-GPU-OPRegion-accesses.patch
      ./0008-HACK-disable-Intel-GPU-AML-generation.patch
      ./0009-temporarily-disable-logging.patch
      ./0010-WIP-Do-not-advertise-hotplug-devices-in-ACPI-VIOT.patch
    ];
  }
)
