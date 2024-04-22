#!/bin/bash
die() {
        echo "$1"
        exit 1
}

install_package() {
        which yum > /dev/null
        if [ $? -eq 0 ]; then
                sudo yum install $1
                return
        fi

        which apt > /dev/null
        if [ $? -eq 0 ]; then
                sudo apt install $1 -y
                return
        fi
}

install_python_package() {
        python -m pip list |grep $1
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

