#!/bin/bash

# install some utilities
install_utilities () {
	pacman -S --noconfirm neovim git alacritty
}

# System clock
system_clock () {
	ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
	hwclock --systohc
}

# Localization
localization () {
	echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
	echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
}

# Bootloader
bootloader () {
	pacman -S --noconfirm grub os-prober efibootmgr
	grub-install --recheck /dev/sda
	grub-mkconfig -o /boot/grub/grub.cfg
}

# set root password
root_password () {
	echo "Root Password: "
	passwd
}

# add new user
new_user () {
	echo -n "username: "
	read USERNAME

	useradd -m $USERNAME
	echo "$USERNAME Password: "
	passwd $USERNAME
}

# add user to wheel group (root)
wheel_group () {
	EDITOR=nvim visudo

	gpasswd -a $USERNAME wheel
}

# hostname
hostname () {
	echo -n "hostname: "
	read HOSTNAME

	echo $HOSTNAME > /etc/hostname
}

# install dhcp client
install_dhcp_client () {
	pacman -S --noconfirm dhcpcd
}

# runit specific install
runit_install () {
	pacman -S --noconfirm connman-runit connman-gtk
	ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default
}

# install yay
install_yay () {
	git clone https://aur.archlinux.org/yay.git
	cd yay
	$USERNAME makepkg -si
	cd ../
	rm -rf yay
}

# install sway
install_sway () {
	pacman -S --noconfirm sway
}

express_installation () {
	# install some utilities
	install_utilities

	# System clock
	system_clock

	# Localization
	localization

	# Bootloader
	bootloader

	# set root password
	root_password

	# add new user
	new_user

	# add user to wheel group (root)
	wheel_group

	# hostname
	hostname

	# install dhcp client
	install_dhcp_client

	# runit specific install
	runit_install

	# install yay
	install_yay

	# install xorg and graphic drivers
	# pacman -S --noconfirm xorg-server xorg-xinit xf86-video-nouveau

	# install sway
	install_sway

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

	# automatic login on tty1
	cp -R /etc/runit/sv/agetty-tty1 /etc/runit/sv/agetty-autologin-tty1
	echo "${AUTOLOGIN}" > /etc/runit/sv/agetty-autologin-tty1/conf
	ln -s /etc/runit/sv/agetty-autologin-tty1 /run/runit/service

	# autostart sway
	echo "${AUTOSTART}" >> /home/$USERNAME/.bash_profile

	# sway config
	su - $USERNAME -c "mkdir $HOME/.config/sway"
	su - $USERNAME -c "cp /etc/sway/config $HOME/.config/sway"
}

custom_installation () {
	for (( ; ; ))
	do
		echo -e "1) Install utilities\n"
		echo -e "2) System clock\n"
		echo -e "3) Localization\n"
		echo -e "4) Bootloader\n"
		echo -e "5) Set root password\n"
		echo -e "6) Add new user\n"
		echo -e "7) Add user to wheel group (root)\n"
		echo -e "8) Hostname\n"
		echo -e "9) Install dhcp client\n"
		echo -e "10) Runit specific install\n"
		echo -e "11) Install yay\n"
		echo -e "12) Install sway\n"
		echo -e "13) Quit\n"

		echo -n "Enter a number: "

		read CHOICE

		case $CHOICE in
			1) install_utilities;;
			2) system_clock;;
			3) localization;;
			4) bootloader;;
			5) root_password;;
			6) new_user;;
			7) wheel_group;;
			8) hostname;;
			9) install_dhcp_client;;
			10) runit_install;;
			11) install_yay;;
			12) install_sway;;
			13) break;;
			*) echo "invalid option";;
		esac
	done
}

echo '
       _     
  __ _(_)___ 
 / _` | / __|
| (_| | \__ \
 \__,_|_|___/
 '

echo -e "1) Express Installation\n"
echo -e "2) Custom Installation\n"

echo -n "Enter a number (default=1): "

read CHOICE

case $CHOICE in
	1) express_installation;;
	2) custom_installation;;
	*) express_installation;;
esac
