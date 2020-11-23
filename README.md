# Build jetson-inference in a docker container

This repo holds a dockerfile to easily build and use jetson-inference on a generic NVIDIA GPU.

### building

To build the container, use: 

```
docker build -t jetson-inference:x86_64 .
```

### example usage

To use the container/framework, use the example binaries & images: 

```
docker run --rm --network=host --gpus all  -it jetson-inference:x86_64 x86_64/bin/imagenet-console x86_64/bin/images/dog_0.jpg
```

Please note you have to setup nvidia-docker beforehand, in order to use the GPU from the container. Further instructions are provided here: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker

This repo holds cache files for the example models used, based on an NVIDIA RTX 2060 SUPER.
