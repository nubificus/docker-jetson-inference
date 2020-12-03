FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

RUN apt-get update && apt-get install -y \
	cmake \
	git \
	libnvinfer-dev \
	libnvinfer-plugin-dev \
	libpython3-dev \
	pkg-config \
	python3-libnvinfer-dev \
	python3-numpy \
	sudo \
	wget \
	&& apt-get clean

RUN git clone --recursive https://github.com/nubificus/jetson-inference
COPY /0001-Enable-RTX-gpu.patch /
COPY /0001-Disable-VERBOSE-logging.patch /
COPY /0001-Disable-Logging.patch /
RUN cd /jetson-inference && \
        git config --global user.name "Builder" && \
        git config --global user.email "builder@nubificus.co.uk" && \
        git am /0001-Enable-RTX-gpu.patch && \
	git am --keep-cr /0001-Disable-VERBOSE-logging.patch && \
	cd utils && git am --keep-cr /0001-Disable-Logging.patch && cd .. && \
        mkdir build && \
        cd build && \
        BUILD_DEPS=YES cmake ../ && \
        make -j$(nproc) && \
        make install -j$(nproc) && \
        cp -a ../utils/image/stb /usr/local/include && \
        mkdir -p /usr/local/networks && cd /jetson-inference/tools && \
        ./download-models.sh NO && \
        cp -avf /jetson-inference/data/networks/* /usr/local/networks && \
        rm -rf /jetson-inference 0001-Enable-RTX-gpu.patch && \
        apt-get clean

# build vaccelrt
WORKDIR /
RUN git clone https://github.com/cloudkernels/vaccelrt
RUN mkdir -p /vaccelrt/build && cd /vaccelrt/build && \
	cmake -DBUILD_PLUGIN_JETSON=ON ../ && \
	make -j$(nproc) install && \
	rm -rf /vaccelrt

# get latest bin files
RUN wget https://github.com/nubificus/fc-x86-guest-build/releases/download/v0.1.1/rootfs.img -O /bin/rootfs.img
RUN wget https://github.com/nubificus/fc-x86-guest-build/releases/download/v0.1.1/vmlinux -O /bin/vmlinux
RUN wget https://github.com/cloudkernels/firecracker/releases/download/vaccel-v0.23.1/firecracker-vaccel -O /bin/firecracker
RUN chmod +x /bin/firecracker

# copy cached Jit built code for RTX 2060 specific GPU & network(s)
COPY cache/bvlc_googlenet.caffemodel.1.1.7201.GPU.FP16.engine /bin/
COPY cache/fcn_resnet18.onnx.1.1.7201.GPU.FP16.engine /bin/
COPY cache/ssd_mobilenet_v2_coco.uff.1.1.7201.GPU.FP16.engine /bin/

# copy fc config & init script
COPY config_vaccel.json config_vaccel.json
COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
