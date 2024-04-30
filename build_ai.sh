#!/bin/bash
WORKSPACE=`pwd`

source $WORKSPACE/scripts/lib.sh

build_acl() {

        if [ ! -d ComputeLibrary ]; then
                git clone https://github.com/ARM-software/ComputeLibrary.git
                cd ComputeLibrary
                git checkout v23.08
        else
                cd ComputeLibrary
        fi

        which scons > /dev/null

        if [ $? -ne 0 ]; then
                install_package scons
        fi

        scons arch=armv8.2-a-sve neon=1 os=linux opencl=0 build=native -j 32 Werror=false validation_tests=0 fixed_format_kernels=1 multi_isa=1 openmp=1 cppthreads=0 || die "failed to build acl"
        echo "finish build acl"
        cd ..
}

install_cmake() {
        wget https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-aarch64.tar.gz
        tar zxf cmake-3.27.7-linux-aarch64.tar.gz
        sudo cp -rvf cmake-3.27.7-linux-aarch64/* /usr/
}

build_onnx() {

        if [ ! -d onnxruntime ]; then
                git clone https://github.com/microsoft/onnxruntime.git
                cd onnxruntime
        else
                cd onnxruntime
        fi

        python3 -m pip install -r requirements.txt.in


        which cmake > /dev/null
        if [ $? -eq 0 ]; then
                cmake --version | grep "3.27.7"
                if [ $? -ne 0 ]; then
                        install_cmake
                fi
        else
                install_cmake
        fi

        ./build.sh   \
                --parallel \
                --config Release \
                --skip_submodule_sync  \
                --skip_tests \
                --build_shared_lib \
                --allow_running_as_root \
                --use_acl ACL_2308 \
                --acl_home $WORKSPACE/ComputeLibrary/ \
                --acl_libs $WORKSPACE/ComputeLibrary/build/


        pushd build/Linux/Release
        sudo make -j $(nproc) install
        popd
        echo "finish build onnxruntime"
        cd ..
}


build_llama() {

        if [ ! -d llama.cpp ]; then
                git clone https://github.com/ggerganov/llama.cpp.git
                cd llama.cpp
        else
                cd llama.cpp
        fi

        make -j $(nproc) || die "failed to build llama"

        cd ../..
}

build_pytorch() {
        install_python_package pyyaml
        install_python_package typing_extensions
        create_repo pytorch https://github.com/pytorch/pytorch
        cd ..
        #git checkout v2.1.1
        git submodule update --init --recursive

        python3 setup.py bdist_wheel || die "failed to build pytorch"
        python3 -m pip list |grep pytorch
        if [ $? -eq 0 ]; then
                echo "pytorch already installed, please remove it before install. bail out"
                exit 1
        fi
        python3 -m pip install ./dist/torch-*.whl --user || die "failed to install pytorch"


        if [ ! -d examples ]; then
                git clone https://github.com/pytorch/examples.git || die "failed to checkout pytorch examples"
        fi
        cd ..
}

build_tf() {
        install_python_package patchelf
        export PATH=$PATH:/home/test/.local/bin/
        create_repo tensorflow https://github.com/tensorflow/tensorflow
        if [ $? -eq 0 ];then
                git checkout v2.14.0
        fi
        cd ..

        if [ ! -f /usr/local/bin/bazel ]; then
          sudo wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
          sudo chmod +x /usr/local/bin/bazel
        fi

        export HOST_C_COMPILER=`which gcc`
        export HOST_CXX_COMPILER=`which g++`
        export PYTHON_BIN_PATH=`which python`
        export USE_DEFAULT_PYTHON_LIB_PATH=1
        export TF_ENABLE_XLA=1
        export TF_DOWNLOAD_CLANG=0
        export TF_SET_ANDROID_WORKSPACE=0
        export TF_NEED_MPI=0
        export TF_NEED_ROCM=0
        export TF_NEED_GCP=0
        export TF_NEED_S3=0
        export TF_NEED_OPENCL_SYCL=0
        export TF_NEED_CUDA=0
        export TF_NEED_HDFS=0
        export TF_NEED_OPENCL=0
        export TF_NEED_JEMALLOC=1
        export TF_NEED_VERBS=0
        export TF_NEED_AWS=0
        export TF_NEED_GDR=0
        export TF_NEED_OPENCL_SYCL=0
        export TF_NEED_COMPUTECPP=0
        export TF_NEED_KAFKA=0
        export TF_NEED_TENSORRT=0
        export TF_NEED_CLANG=0
        export CC_OPT_FLAGS="-Wno-sign-compare"

        ./configure
        bazel build //tensorflow/tools/pip_package:build_pip_package || die "failed to build tensorflow"
        if [ ! -d tmp ]; then
                mkdir tmp
        fi
        ./bazel-bin/tensorflow/tools/pip_package/build_pip_package tmp/ || die "failed to package tensorflow"

        cd ..
}


build_onednn() {
        if [ ! -f ComputeLibrary/build/libarm_compute.so ]; then
                echo "please build ACL before building onednn"
                exit 1
        fi

        create_repo oneDNN https://github.com/oneapi-src/oneDNN.git

        export ACL_ROOT_DIR=$WORKSPACE/ComputeLibrary

        cmake .. -DDNNL_AARCH64_USE_ACL=ON || die "failed to cmake onednn"
        make -j $(nproc) || die "failed to build onednn"

        cd ../..
}

build_all() {
        build_acl
        build_onnx
        build_llama
        build_pytorch
        build_tf
}


SECONDS=0


case "$1" in
  "onnx")
    build_onnx
    ;;
  "acl")
    build_acl
    ;;
  "llama")
    build_llama
    ;;
  "pytorch")
    build_pytorch
    ;;
  "tf")
    build_tf
    ;;
  "onednn")
    build_onednn
    ;;
  "")
    build_all
    ;;
  *)
    echo "The first command-line option is: $1"
    ;;
esac


ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo "build done, $ELAPSED"

