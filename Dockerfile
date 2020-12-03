FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
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

COPY /0001-Enable-RTX-gpu.patch /
RUN git clone --recursive https://github.com/dusty-nv/jetson-inference
RUN cd /jetson-inference && \
	git config user.name "Builder" && \
	git config user.email "builder@nubificus.co.uk" && \
	git am /0001-Enable-RTX-gpu.patch && \
	mkdir build && \
	cd build && \
	cmake -DBUILD_INTERACTIVE=NO ../ && \
	make -j$(nproc) && \
	make install -j$(nproc) && \
	cp -a ../utils/image/stb /usr/local/include && \
	mkdir /usr/local/share/jetson-inference/tools && \
	cp ../tools/download-models.sh /usr/local/share/jetson-inference/tools/ && \
	sed 's/BUILD_INTERACTIVE=.*/BUILD_INTERACTIVE=0/g' \
		-i /usr/local/share/jetson-inference/tools/download-models.sh && \
	unlink /usr/local/bin/images && unlink /usr/local/bin/networks

RUN rm -rf /jetson-inference 0001-Enable-RTX-gpu.patch

WORKDIR /
