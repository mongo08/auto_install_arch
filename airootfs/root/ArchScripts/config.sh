#!/usr/bin/env bash

SCRIPTFILE=${0##*/}
PRINTERFILE="printer.sh"
ENVFILE="env.sh"

source /root/$PRINTERFILE
source /root/$ENVFILE

set_zoneinfo()
{
    print_message ">>> Linking zoneinfo <<<"
    ln -s /usr/share/zoneinfo/$ZONEINFO /etc/localtime -f
}

enable_utc()
{
    print_message ">>> Setting time <<<"
    hwclock --systohc --utc
}

set_language()
{
    print_message ">>> Enabling language and keymap <<<"

    sed -i "s/#\($LANGUAGE\.UTF-8\)/\1/" /etc/locale.gen
    echo "LANG=$LANGUAGE.UTF-8" > /etc/locale.conf
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    locale-gen
}

set_hostname()
{
    print_message ">>> Creating hostname $HOSTNAME <<<"
    echo $HOSTNAME > /etc/hostname
}

enable_networking()
{
    print_message ">>> Enabling networking <<<"

    if [[ $(pacman -Qsq networkmanager) ]]; then
        systemctl enable NetworkManager.service
    else
        systemctl enable systemd-networkd.service
        systemctl enable systemd-resolved.service
    fi
}

enable_desktop_manager()
{
    print_message ">>> Enabling display manager <<<"
    if [[ $(pacman -Qsq sddm) ]]; then
        systemctl enable sddm.service
    elif [[ $(pacman -Qsq gdm) ]]; then
        systemctl enable gdm.service
    fi
}

setup_root_account()
{
    print_message ">>> Setting root account <<<"
    chsh -s $USERSHELL
    # groupadd nopasswdlogin
    # gpasswd --add root nopasswdlogin
    # This is insecure AF, don't use this if your machine is being monitored
    echo "root:$PASSWORD" | chpasswd
}

setup_user_account()
{
    print_message ">>> Creating $USERNAME account <<<"
    useradd -m -G wheel -s $USERSHELL $USERNAME

    # This is insecure AF, don't use this if your machine is being monitored
    echo "$USERNAME:$PASSWORD" | chpasswd

    print_message ">>> Enabling sudo for $USERNAME <<<"
    sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL:ALL)\s\NOPASSWD: ALL\)/\1/' /etc/sudoers
    sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL:ALL)\s\ALL\)/\1/' /etc/sudoers
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
    sed -i /etc/gdm/custom.conf -re 's/^#WaylandEnable=false.*/#WaylandEnable=false\n# Enabling automatic login\nAutomaticLoginEnable = true\nAutomaticLogin = user\n/g'
    sed -i /etc/pam.d/gdm-password -re 's/^#%PAM-1.0.*/#%PAM-1.0\n\nauth sufficient pam_succeed_if.so user ingroup nopasswdlogin/g'
    groupadd nopasswdlogin
    usermod -a -G nopasswdlogin -s $USERSHELL $USERNAME
    systemctl start StartPO.service
    systemctl enable StartPO.service
}

install_grub()
{
    grub-install $(findmnt / -o SOURCE | tail -n 1 | awk -F'[0-9]' '{ print $1 }') --force
    grub-mkconfig -o /boot/grub/grub.cfg
}

install_refind()
{
    # Bait refind-install into thinking that a refind install already exists,
    # so it will "upgrade" (install) in desired location /boot/EFI/refind
    # This is done to avoid moving Microsoft's original bootloader.

    # Comment the following two lines if you have an HP computer
    # (suboptimal EFI implementation), or you don't mind moving
    # the original bootloader.
    mkdir -p /boot/EFI/refind
    cp /usr/share/refind/refind.conf-sample /boot/EFI/refind/refind.conf

    refind-install
    REFIND_UUID=$(cat /etc/fstab | grep UUID | grep "/ " | cut --fields=1)
    echo "\"Boot using default options\"     \"root=${REFIND_UUID} rw add_efi_memmap initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-linux.img" > /boot/refind_linux.conf
    echo "\"Boot using fallback initramfs\"  \"root=${REFIND_UUID} rw add_efi_memmap initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-linux-fallback.img" >> /boot/refind_linux.conf
    echo "\"Boot to terminal\"               \"root=${REFIND_UUID} rw add_efi_memmap initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-linux.img systemd.unit=multi-user.target" >> /boot/refind_linux.conf
}

install_bootloader()
{
    print_message ">>> Installing $BOOTLOADER bootloader <<<"

    if [[ $(pacman -Qsq grub) ]]; then
        install_grub
    elif [[ $(pacman -Qsq refind) ]]; then
        install_refind
    fi
}

clean_up()
{
    print_success ">>> Ready! Cleaning up <<<"

    rm $ENVFILE -vf
    rm $PRINTERFILE -vf
    rm $SCRIPTFILE -vf
}

main()
{
    set_zoneinfo &&
    enable_utc &&
    set_language &&
    set_hostname &&
    enable_networking &&
    enable_desktop_manager &&
    setup_root_account &&
    setup_user_account &&
    install_bootloader &&
    clean_up
}

# Execute main
main

