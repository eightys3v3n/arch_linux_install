#!/usr/bin/bash


PACMAN_INSTALL_CMD="pacman -S --noconfirm"
PACMAN_UPGRADE_CMD="pacman -U --noconfirm"
GIT_CLONE_CMD="git clone"

CLONE_DIR="/tmp/aurutils"
GIT_REPO="https://aur.archlinux.org/aurutils.git"
DEPS="base-devel"

has_required() {
	type $1 1>/dev/null 2>/dev/null
}

dl_install() {
	$PACMAN_INSTALL_CMD $@
}

install_deps() {
	dl_install $DEPS
}

clone_repo() {
	if [ -d $CLONE_DIR ]
	then
		echo $CLONE_DIR already exists
		return 1
	fi
	$GIT_CLONE_CMD $GIT_REPO $CLONE_DIR
}

upgrade_aurutils() {
	$PACMAN_UPGRADE_CMD aurutils*.tar.xz
}

main() {
	if [[ "$USER" != "root" ]]
	then
		echo This script needs to be run as root
		return 1
	fi

	read -p "Non-root user to build with: " NON_ROOT_USER

	if ( ! has_required git )
	then
		echo This script requires git, attempting to install...
		if ( dl_install git )
		then
			echo "Couldn't install git"
			return 1
		fi

		return 1
	fi

	if ( ! install_deps )
	then
		echo Failed to install dependancies: $DEPS
		return 1
	fi

	if ( ! clone_repo )
	then
		echo Failed to clone repository
		return 1
	fi

	if ( ! chmod -R 777 $CLONE_DIR )
	then
		echo "Failed to 'chmod -R 777 $CLONE_DIR'"
		return 1
	fi
	pushd $CLONE_DIR

	if ( ! su -c makepkg $NON_ROOT_USER )
	then
		echo Failed to make package as non-root user
		return 1
	fi

	if ( ! upgrade_aurutils ) 
	then
		echo Failed to install built package
		return 1
	fi

	popd
}

main