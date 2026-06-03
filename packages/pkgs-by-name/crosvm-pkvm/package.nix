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
    ];
  }
)
