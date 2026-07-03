# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  # System name
  name = "Lenovo X1 Carbon Gen 12";

  # List of system SKUs covered by this configuration
  skus = [
    "LENOVO_MT_21KC_BU_Think_FM_ThinkPad X1 Carbon Gen 12 21KC006CMX"
    "LENOVO_MT_21KD_BU_Think_FM_ThinkPad X1 Carbon Gen 12 21KDS87D00"
    # TODO Add more SKUs
  ];

  host = {
    kernelConfig.kernelParams = [
      # FIXME: pKVM requires sm_off due to no NEST support
      # FIXME: sp_off is a workaround for crosvm+viommu
      # FIXME: debug_flush_all forces domain wide flushes for crosvm+stock kernel
      "intel_iommu=on,sm_off,sp_off,debug_flush_all"
      # FIXME: workaround for PLANE ATS fault with crosvm+viommu
      "pci=noats"
      "iommu=pt"
      "module_blacklist=i915,xe,snd_pcm,mei_me,bluetooth,btusb" # Prevent kernel modules from being accidentally used by host
      "acpi_backlight=vendor"
      "acpi_osi=linux"
    ];
  };

  input = {
    # keyboard = {
    #   name = [ "AT Translated Set 2 keyboard" ];
    #   evdev = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
    # };

    # mouse = {
    #   name = [ "TPPS/2 Elan TrackPoint" ];
    #   evdev = [ "/dev/input/by-path/platform-i8042-serio-1-event-mouse" ];
    # };

    # touchpad = {
    #   name = [ "SNSL0028:00 2C2F:0028 Touchpad" ];
    #   evdev = [ "/dev/input/by-path/pci-0000:00:15.0-platform-i2c_designware.0-event-mouse" ];
    # };

    misc = {
      name = [ "ThinkPad Extra Buttons" ];
      evdev = [ "/dev/input/by-path/platform-thinkpad_acpi-event" ];
    };
  };

  network.pciDevices = [
    {
      # Network controller [0280]: Intel Corporation Meteor Lake PCH CNVi WiFi [8086:7e40](rev 20)
      # iwlwifi
      path = "0000:00:14.3";
      vendorId = "8086";
      productId = "7e40";
      name = "wlp0s5f0";
    }
  ];

  gpu = {
    pciDevices = [
      {
        # VGA compatible controller [0300]: Intel Corporation Meteor Lake-P [Intel Graphics] [8086:7d45] (rev 08)
        # i915,xe
        path = "0000:00:02.0";
        vendorId = "8086";
        productId = "7d45";
      }
    ];
    kernelConfig = {
      stage1.kernelModules = [
        "i915"
        "xe"
      ];
      kernelParams = [
        "earlykms"
      ];
    };
  };

  # With the current implementation, the whole PCI IOMMU group 14:
  #   00:1f.x in the example from Lenovo X1 Carbon
  #   must be defined for passthrough to AudioVM
  audio = {
    pciDevices = [
      {
        # ISA bridge: Intel Corporation Device 7e03 (rev 20)
        path = "0000:00:1f.0";
        vendorId = "8086";
        productId = "7e03";
      }
      {
        # Audio device: Intel Corporation Meteor Lake-P HD Audio Controller (rev 20) (prog-if 80)
        path = "0000:00:1f.3";
        vendorId = "8086";
        productId = "7e28";
      }
      {
        # SMBus: Intel Corporation Meteor Lake-P SMBus Controller (rev 20)
        path = "0000:00:1f.4";
        vendorId = "8086";
        productId = "7e22";
      }
      {
        # Serial bus controller: Intel Corporation Meteor Lake-P SPI Controller (rev 20)
        path = "0000:00:1f.5";
        vendorId = "8086";
        productId = "7e23";
      }
    ];
    kernelConfig.kernelParams = [ "snd_intel_dspcfg.dsp_driver=0" ];
  };

  usb.devices = [
    # Integrated camera
    {
      name = "cam0";
      hostbus = "3";
      hostport = "9";
    }
    # Fingerprint reader
    {
      name = "fpr0";
      hostbus = "3";
      hostport = "7";
    }
    # Bluetooth controller
    {
      name = "bt0";
      hostbus = "3";
      hostport = "10";
    }
  ];
}
