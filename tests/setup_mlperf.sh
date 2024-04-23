#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
pushd $SCRIPT_DIR
cd ..
TOP_DIR=$(pwd)
popd

source $TOP_DIR/scripts/lib.sh

MLPERF_DIR=${HOME}/examples/MLCommons

if [  -d $MLPERF_DIR/inference ]; then
	exit 0
fi

[ ! -d $MLPERF_DIR ] && mkdir -p $MLPERF_DIR

is_root=`id -u`
if [ $is_root -eq 0 ]; then
	apt update
else
	sudo apt update
fi
install_package build-essential
install_package git
install_python_package pybind11
install_python_package protobuf
#install_package pybind11-dev

cd $MLPERF_DIR

git clone https://github.com/mlcommons/inference.git --recursive || die "failed to clone mlperf"
cd inference/
git checkout v2.1 || die "failed to checkout v2.1"

patch -p1 < $TOP_DIR/patches/pytorch.patch || die "failed to patch pytorch"

#git submodule init
#git submodule update --remote --recursive
cd loadgen

# Run command to get pybind11 installation directory
include_dir=$(python -c "import pybind11; print(pybind11.get_include())")

# Modify setup.py file to add the include directory
sed -i "s|include_dirs=\[\".\", \"../third_party/pybind/include\"\]|include_dirs=\[\".\", \"../third_party/pybind/include\", \"$include_dir\"\]|" setup.py

CFLAGS="-std=c++14" python setup.py develop || die "failed to build loadgen"
cd $MLPERF_DIR/inference/vision/classification_and_detection
python setup.py develop || die "failed to build classification"

