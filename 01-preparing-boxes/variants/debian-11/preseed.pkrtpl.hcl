### Localization
d-i debian-installer/language string ${var.guest-os-language}
d-i debian-installer/country string ${var.guest-os-country}
d-i debian-installer/locale string ${var.guest-os-locale}
# d-i debian-installer/language string en
# d-i debian-installer/country string FR
# d-i debian-installer/locale string en_US.UTF-8
## Keyboard
# d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select ${var.guest-os-keyboard-layout}
d-i console-keymaps-at/keymap select ${var.guest-os-keyboard-layout}
d-i debian-installer/keymap string ${var.guest-os-keyboard-layout}

### Network configuration
d-i netcfg/choose_interface select auto
d-i netcfg/wireless_wep string

### Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string ${var.guest-os-mirror-hostname}
d-i mirror/http/directory string ${var.guest-os-mirror-path}
d-i mirror/http/proxy string

### Account setup
# Skip creation of a root account (normal user account will be able to use sudo).
d-i passwd/root-login boolean false

# create the user account, password = vagrant as per https://www.vagrantup.com/docs/boxes/base
d-i passwd/user-fullname string ${var.ssh-username}
d-i passwd/user-uid string 1000
d-i passwd/username string ${var.ssh-username}
d-i passwd/user-password password ${var.ssh-username}
d-i passwd/user-password-again password ${var.ssh-username}
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

### Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string ${var.guest-os-timezone}
d-i clock-setup/ntp boolean true

### Partitioning
## Init
d-i partman-auto/disk string /dev/sda
d-i partman-auto/method string lvm
## Discard warnings about removing existing partitions
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto-lvm/guided_size string max
## GPT/UEFI
d-i partman-efi/non_efi_system boolean true
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
## Recipe
d-i partman-base partman/default_filesystem string ext4
d-i partman-auto/expert_recipe string         \
  efi-boot-lvm-root ::                        \
    1 1 1 free                                \
      $bios_boot{ }                           \
      method{ biosgrub }                      \
    .                                         \
    128 128 128 fat32                         \
      $primary{ }                             \
      method{ efi }                           \
      format{ }                               \
    .                                         \
    512 512 512 ext4                          \
      $primary{ }                             \
      $bootable{ }                            \
      method{ format }                        \
      format{ }                               \
      use_filesystem{ }                       \
      filesystem{ ext4 }                      \
      mountpoint{ /boot }                     \
    .                                         \
    1 1 -1 $default_filesystem                \
      $defaultignore{ }                       \
      $primary{ }                             \
      method{ lvm }                           \
      vg_name{ volume }                       \
    .                                         \
    1 1 -1 ext4                               \
      $lvmok{ }                               \
      $in_vg{ volume }                        \
      $lv_name{ root }                        \
      method{ format }                        \
      format{ }                               \
      use_filesystem{ }                       \
      filesystem{ ext4 }                      \
      mountpoint{ / }                         \
    .
## Confirm
d-i partman-basicfilesystems/no_swap boolean false
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/confirm boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
## Partitions mount convention (use label instead of UUID)
#d-i partman/mount_style select traditional

### Package selection
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-next boolean false
d-i apt-setup/cdrom/set-failed boolean false
d-i base-installer/install-recommends boolean false
tasksel tasksel/first multiselect ssh-server
d-i pkgsel/install-language-support boolean false
popularity-contest popularity-contest/participate boolean false
d-i apt-setup/services-select multiselect security, updates

### Boot loader installation
#d-i grub-installer/only_debian boolean false
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string /dev/sda

### Finishing up the installation
d-i finish-install/keep-consoles boolean true
d-i finish-install/reboot_in_progress note

### Inject the vagrant ssh key
d-i preseed/late_command string \
mkdir -p /target/home/${var.ssh-username}/.ssh && \
echo '${var.ssh-public-key}' > /target/home/${var.ssh-username}/.ssh/authorized_keys && \
chmod 0400 /target/home/${var.ssh-username}/.ssh/authorized_keys && \
chown -R 1000:1000 /target/home/${var.ssh-username}/.ssh && \
echo "${var.ssh-username}        ALL=(ALL)       NOPASSWD: ALL" >> /target/etc/sudoers.d/${var.ssh-username} && \
apt-install grub2-common && \
apt-install grub-efi-amd64-bin && \
#### Disable wait in grub menu
sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /target/etc/default/grub && \
echo "GRUB_HIDDEN_TIMEOUT=0" >> /target/etc/default/grub && \
echo "GRUB_HIDDEN_TIMEOUT_QUIET=true" >> /target/etc/default/grub && \
in-target --pass-stdout grub-install --force-extra-removable --no-nvram && \
in-target --pass-stdout update-grub