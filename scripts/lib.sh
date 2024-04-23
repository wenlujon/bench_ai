#!/bin/bash
die() {
        echo "$1"
        exit 1
}

install_package() {
	is_root=`id -u`
        which yum > /dev/null
        if [ $? -eq 0 ]; then
		if [ $is_root -eq 0 ]; then
			yum install $1 -y
		else
			sudo yum install $1 -y
		fi
                return
        fi

        which apt > /dev/null
        if [ $? -eq 0 ]; then
		if [ $is_root -eq 0 ]; then
			apt install $1 -y
		else
			sudo apt install $1 -y
		fi

                return
        fi
}

install_python_package() {
	pip show $1 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
                python -m pip install $1 $2
        fi
}

create_repo() {
        repo=$1
        url=$2
        if [ ! -d $repo ]; then
                git clone $url
                cd $repo
                mkdir build && cd build
                return 0
        else
                cd $repo
                cd build
                return 1
        fi
}

