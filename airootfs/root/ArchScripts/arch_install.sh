#!/usr/bin/env bash

SCRIPTFILE=${0##*/}
MOUNTPOINT="/mnt"

BASEDIR=$(readlink -f ${0%/*})
RECIPESDIR="${BASEDIR}/recipes"

PRINTERFILE="printer.sh"
ENVFILE="env.sh"
CONFFILE="config.sh"

PRINTERPATH="${BASEDIR}/${PRINTERFILE}"
ENVPATH="${BASEDIR}/${ENVFILE}"
CONFPATH="${BASEDIR}/${CONFFILE}"

# --------------------------------------- #

# Use this for OFFLINE installation (ArchISOMaker)
CACHEDIR="/root/pkg"
PACMANPATH="${BASEDIR}/pacman_custom.conf"

# Use this if for ONLINE installation
#CACHEDIR="${MOUNTPOINT}/var/cache/pacman/pkg"
#PACMANPATH="/etc/pacman.conf"

# --------------------------------------- #

source $PRINTERPATH
source $ENVPATH

select_base_packages()
{
    print_message "Selecting base packages..."

    source "${RECIPESDIR}/base/minimal.sh"
    export PACKAGES="${PACKAGES} ${RECIPE_PKGS}"

    source "${RECIPESDIR}/base/utilities.sh"
    export PACKAGES="${PACKAGES} ${RECIPE_PKGS}"
}

select_desktop_environment()
{
    print_message "Selecting ${DESKTOP_ENV}..."

    source "${RECIPESDIR}/desktops/${DESKTOP_ENV}.sh"
    export PACKAGES="${PACKAGES} ${RECIPE_PKGS}"
}

select_bootloader()
{
    print_message "Selecting ${BOOTLOADER}..."

    source "${RECIPESDIR}/bootloaders/${BOOTLOADER}.sh"
    export PACKAGES="${PACKAGES} ${RECIPE_PKGS}"
}

select_video_drivers()
{
    print_message "Selecting ${XORG_DRIVERS} drivers..."

    source "${RECIPESDIR}/video_drivers/${XORG_DRIVERS}.sh"
    export PACKAGES="${PACKAGES} ${RECIPE_PKGS}"
}

install_packages()
{
    print_message "Installing packages..."
    pacstrap -C $PACMANPATH $MOUNTPOINT $PACKAGES --cachedir=$CACHEDIR --needed
}

generate_fstab()
{
    genfstab -p -U $MOUNTPOINT > $MOUNTPOINT/etc/fstab
}

copy_scripts()
{
    cp $ENVPATH $MOUNTPOINT/root -v
    cp $CONFPATH $MOUNTPOINT/root -v
    cp $PRINTERPATH $MOUNTPOINT/root -v
}

configure_system()
{
    print_warning ">>> Configuring your system with $DESKTOP_ENV, $BOOTLOADER and $XORG_DRIVERS... <<<"
    arch-chroot $MOUNTPOINT /bin/zsh -c "cd && ./$CONFFILE && rm $CONFFILE $ENVFILE -f"
}

check_mounted_drive() {
    if [[ $(findmnt -M "$MOUNTPOINT") ]]; then
        print_success "Drive mounted in $MOUNTPOINT."
    else
        print_failure "Drive is NOT MOUNTED!"
        print_warning "Mount your drive in '$MOUNTPOINT' and re-run '$SCRIPTFILE' to install your system."
        exit 1
    fi
}

install_system()
{
    select_base_packages
    select_desktop_environment
    select_bootloader
    select_video_drivers

    install_packages
    generate_fstab
    copy_scripts

    configure_system
}

verify_installation()
{
    [[ ! -f $MOUNTPOINT/root/$CONFFILE && ! -f $MOUNTPOINT/root/$ENVFILE && ! -f $MOUNTPOINT/root/$PRINTERFILE ]]
}

mount_disk()
{
    (echo d; echo g; echo n; echo 1; echo 2048 ;echo +32G; echo w) | fdisk /dev/sda
    # cfdisk -z /dev/sda 
    mkfs.ext4 /dev/sda -L 'Arch'
    mount /dev/sda /mnt
}

main()
{
    mount_disk
    # Check pre-install state
    check_mounted_drive

    # Install and verify
    install_system
    verify_installation
    python3 autologin.py
    # Message at end
    if [[ $? == 0 ]]; then
        print_success "Installation finished! You can reboot now."
    else
        print_failure "Installation failed! Check errors before trying again."
        exit 1
    fi
}

# Execute main
main $@