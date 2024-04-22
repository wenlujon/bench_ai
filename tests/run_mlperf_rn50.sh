#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
pushd $SCRIPT_DIR
cd ..
TOP_DIR=$(pwd)
popd

$TOP_DIR/tests/setup_mlperf.sh

source $TOP_DIR/scripts/lib.sh

pip show ck > /dev/null
if [ $? -ne 0 ]; then
	install_python_package ck==1.55.5
fi

export DATA_DIR=/data/datasets/dataset-imagenet-ilsvrc2012-val-min
export MODEL_DIR=/data/models

if [ ! -f ~/.setup_rn50 ]; then
        #python3 -m pip install onnxruntime==1.12.0
        #pip install tokenization scikit-learn tensorboard numpy==1.23.4 deepmerge

        # Download imagenet validation set
        if [ ! -d $DATA_DIR ]; then
                echo "downloading imagenet datasets"

		ck pull repo:ck-env
		echo "1" | ck install package --tags=image-classification,dataset,imagenet,aux
		echo "1" | ck install package --tags=image-classification,dataset,imagenet,val

		# Copy the labels into the image location
		cp ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-aux/val.txt ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min/val_map.txt


                mv ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min /data/datasets/
        fi

        pushd $MODEL_DIR
        if [ ! -f resnet50_v1.pb ]; then
		wget -O resnet50_v1.pb https://zenodo.org/record/2535873/files/resnet50_v1.pb || die "failed to download"
	fi
        if [ ! -f resnet50-19c8e357.pth ]; then
		wget -O resnet50-19c8e357.pth https://zenodo.org/record/4588417/files/resnet50-19c8e357.pth || die "failed to download"
	fi
        if [ ! -f resnet50_v1.onnx ]; then
		wget -O resnet50_v1.onnx https://zenodo.org/record/2592612/files/resnet50_v1.onnx || die "failed to download"
	fi
        popd

        touch ~/.setup_rn50
fi

STREAM=MultiStream

USER_CONF=$HOME/examples/MLCommons/inference/vision/classification_and_detection/user.conf

if [ "$1" == "single" ]; then
        STREAM=SingleStream
        sed -i '/min_query_count/d' $USER_CONF
        sed -i '/performance_sample_count_override/d' $USER_CONF
else
        grep 'min_query_count = 1' $USER_CONF > /dev/null

        if [ $? -ne 0 ]; then
                echo '' >> $USER_CONF
                echo '*.*.min_query_count = 1' >> $USER_CONF
                echo '*.*.performance_sample_count_override = 1' >> $USER_CONF
        fi

fi

cd $HOME/examples/MLCommons/inference/vision/classification_and_detection

./run_local.sh $2 resnet50 cpu --scenario $STREAM
