#!/bin/bash

# System clock
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8" > /etc/locale.gen
echo "de_DE.UTF-8" >> /etc/locale.gen
locale-gen

# Bootloader
pacman -S grub os-prober efibootmgr
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# set root password
passwd

# add new user
echo "username: "
read USERNAME

useradd -m $USERNAME
passwd $USERNAME

# add user to wheel group (root)
EDITOR=nvim visudo

gpasswd -a $USERNAME wheel

# hostname
echo "hostname: "
read HOSTNAME

echo $HOSTNAME > /etc/hostname

# install dhcp client
pacman -S dhcpcd

# runit specific install
pacman -S connman-runit connman-gtk
ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

# install git
pacman -S git

# install yay
git clone https://aur.archlinux.org/yay.git
chown -R $USERNAME:$USERNAME yay
cd yay
sudo su $USERNAME makepkg -si
rm -rf yay

# install xorg and graphic drivers
pacman -S xorg-server xorg-xinit xf86-video-nouveau
