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
COPY /ji.patch /
RUN cd /jetson-inference && git checkout 0a75e3059 && patch -p1 < /ji.patch
#COPY /0001-Enable-RTX-gpu.patch /
#COPY /0001-Disable-VERBOSE-logging.patch /
#COPY /0001-Disable-Logging.patch /
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get -y install python3.7
RUN cd /jetson-inference && git submodule update --init  && \
        git config --global user.name "Builder" && \
        git config --global user.email "builder@nubificus.co.uk" && \
        mkdir build && \
        cd build && \
        BUILD_DEPS=YES cmake -DBUILD_INTERACTIVE=NO ../ && \
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
RUN git clone https://github.com/cloudkernels/vaccelrt -b classify_test
RUN mkdir -p /vaccelrt/build && cd /vaccelrt/build && \
	cmake -DBUILD_PLUGIN_JETSON=ON -DBUILD_EXAMPLES=ON ../ && \
	make -j$(nproc) install && \
	rm -rf /vaccelrt

RUN apt-get install -y curl

ARG RELEASE=v0.1.3
RUN wget https://github.com/nubificus/fc-x86-guest-build/releases/download/${RELEASE}/vmlinux -O /bin/vmlinux && \
    wget https://github.com/nubificus/fc-x86-guest-build/releases/download/${RELEASE}/rootfs.img -O /bin/rootfs.img
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
