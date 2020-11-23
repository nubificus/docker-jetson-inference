FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

RUN apt-get update
RUN apt-get install -y git cmake libpython3-dev python3-numpy wget
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
RUN apt install ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb


RUN git clone --recursive https://github.com/dusty-nv/jetson-inference
WORKDIR /jetson-inference
RUN apt install -y libnvinfer-dev libnvinfer-plugin-dev python3-libnvinfer-dev
COPY /0001-Enable-RTX-gpu.patch /
WORKDIR /jetson-inference
RUN git am /0001-Enable-RTX-gpu.patch
RUN mkdir build

WORKDIR /jetson-inference/build

RUN cmake ../
RUN make install -j$(nproc)
RUN ./download-models.sh NO

# copy cached device code
COPY cache/bvlc_googlenet.caffemodel.1.1.7201.GPU.FP16.engine /jetson-inference/build/x86_64/bin/networks/bvlc_googlenet.caffemodel.1.1.7201.GPU.FP16.engine
COPY cache/ssd_mobilenet_v2_coco.uff.1.1.7201.GPU.FP16.engine /jetson-inference/build/x86_64/bin/networks/SSD-Mobilenet-v2/ssd_mobilenet_v2_coco.uff.1.1.7201.GPU.FP16.engine
COPY cache/fcn_resnet18.onnx.1.1.7201.GPU.FP16.engine /jetson-inference/build/x86_64/bin/networks/FCN-ResNet18-Pascal-VOC-320x320/fcn_resnet18.onnx.1.1.7201.GPU.FP16.engine

