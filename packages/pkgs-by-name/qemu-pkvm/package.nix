# Copyright 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  ghaf-qemu,
  fetchpatch,
  ...
}:
ghaf-qemu.overrideAttrs (
  _finalAttrs: oldAttrs: {
    patches = oldAttrs.patches ++ [
      (fetchpatch {
        url = "https://raw.githubusercontent.com/jkrh/pkvm-x86/bfded00f32f3cba69c4ea7a082fab9ef0898eab8/patches/qemu/0001-qemu-Add-support-for-pKVM.patch";
        hash = "sha256-p1FHTfxeABBW2vFZQexdRY/w8w3kXU+aX87ZEhUb+xQ=";
      })
    ];
  }
)
