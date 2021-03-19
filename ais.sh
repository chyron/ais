#!/bin/bash

AUTOLOGIN=$(cat <<EOF
if [ -x /sbin/agetty -o -x /bin/agetty ]; then
	# util-linux specific settings
	if [ "\${tty}" = "tty1" ]; then
		GETTY_ARGS="--autologin $USERNAME --noclear"
	fi
fi

BAUD_RATE=38400
TERM_NAME=linux
EOF
)

AUTOSTART=$(cat <<EOF
if [ -z \$DISPLAY ] && [ "\$(tty)" == "/dev/tty1" ]; then
	exec sway
fi
EOF
)

express_installation () {
	# arch base system and kernel
	pacman -S --noconfirm base base-devel runit elogind-runit linux linux-firmware

	# install some utilities
	pacman -S --noconfirm neovim git

	# System clock
	ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
	hwclock --systohc

	# Localization
	echo "en_US.UTF-8" > /etc/locale.gen
	echo "de_DE.UTF-8" >> /etc/locale.gen
	locale-gen

	# Bootloader
	pacman -S --noconfirm grub os-prober efibootmgr
	grub-install --recheck /dev/sda
	grub-mkconfig -o /boot/grub/grub.cfg

	# set root password
	echo -n "Root Password: "
	passwd

	# add new user
	echo -n "username: "
	read USERNAME

	useradd -m $USERNAME
	echo -n "$USERNAME Password: "
	passwd $USERNAME

	# add user to wheel group (root)
	EDITOR=nvim visudo

	gpasswd -a $USERNAME wheel

	# hostname
	echo -n "hostname: "
	read HOSTNAME

	echo $HOSTNAME > /etc/hostname

	# install dhcp client
	pacman -S --noconfirm dhcpcd

	# runit specific install
	pacman -S --noconfirm connman-runit connman-gtk
	ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

	# install yay
	# git clone https://aur.archlinux.org/yay.git
	# chown -R $USERNAME:$USERNAME yay
	# cd yay
	# sudo su $USERNAME makepkg -si
	# rm -rf yay

	# install xorg and graphic drivers
	# pacman -S --noconfirm xorg-server xorg-xinit xf86-video-nouveau

	# install sway
	pacman -S --noconfirm sway

	# automatic login on tty1
	cp -R /etc/runit/sv/agetty-tty1 /etc/sv/agetty-autologin-tty1
	echo "${AUTOLOGIN}" > /etc/runit/sv/agetty-autologin-tty1/conf
	ln -s /etc/runit/sv/agetty-autologin-tty1 /run/runit/service

	# autostart sway
	echo "${AUTOSTART}" >> /home/$USERNAME/.bash_profile

	# sway config
	su - $USERNAME -c "mkdir $HOME/.config/sway"
	su - $USERNAME -c "cp /etc/sway/config $HOME/.config/sway"
}

echo '
       _     
  __ _(_)___ 
 / _` | / __|
| (_| | \__ \
 \__,_|_|___/
 '

echo -e "1) Express Installation\n"

echo -n "Enter a number (default=1): "

read CHOICE

case $CHOICE in
	1) express_installation;;
	*) express_installation;;
esac
