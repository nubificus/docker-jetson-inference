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
	&& rm -rf /var/lib/apt/lists/*

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
	wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb && \
	apt install ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb

COPY /0001-Enable-RTX-gpu.patch /
RUN git clone --recursive https://github.com/dusty-nv/jetson-inference
RUN cd /jetson-inference && \
	git config user.name "Builder" && \
	git config user.email "builder@nubificus.co.uk" && \
	git am /0001-Enable-RTX-gpu.patch && \
	mkdir build && \
	cd build && \
	BUILD_DEPS=YES cmake ../ && \
	make -j$(nproc) && \
	make install -j$(nproc) && \
	cp -a ../utils/image/stb /usr/local/include

# download & copy networks
RUN mkdir -p /usr/local/networks && cd /jetson-inference/tools && \
	./download-models.sh NO && \
        cp -avf /jetson-inference/data/networks/* /usr/local/networks

# cleanup
RUN rm -rf /jetson-inference 0001-Enable-RTX-gpu.patch

# build vaccelrt
WORKDIR /
RUN git clone https://github.com/cloudkernels/vaccelrt
RUN mkdir -p /vaccelrt/build
WORKDIR /vaccelrt/build
RUN cmake -DBUILD_PLUGIN_JETSON=ON ../
RUN make -j$(nproc) install
WORKDIR /
# cleanup
RUN rm -rf /vaccelrt

# copy bin files (will be replaced from wget release assets)
COPY /bin/vmlinux /bin/vmlinux
COPY /bin/rootfs.img.xz /bin/rootfs.img.xz
COPY /bin/firecracker /bin/firecracker

# copy cached Jit built code for the specific GPU & network
COPY cache/bvlc_googlenet.caffemodel.1.1.7201.GPU.FP16.engine /bin/
COPY cache/fcn_resnet18.onnx.1.1.7201.GPU.FP16.engine /bin/
COPY cache/ssd_mobilenet_v2_coco.uff.1.1.7201.GPU.FP16.engine /bin/

# copy fc config & init script
COPY config_vaccel.json config_vaccel.json
COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
