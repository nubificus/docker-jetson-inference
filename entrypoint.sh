#!/bin/bash

FC_BIN=/bin/firecracker
NETWORKS=/usr/local/networks
KERNEL=./bin/vmlinux
ROOTFS=./bin/rootfs.img.xz
FC_CONFIG=config_vaccel.json

echo "Uncompressing rootfs..."
xzcat $ROOTFS > rootfs.img

ln -s $NETWORKS ./networks
ln -s $KERNEL ./vmlinux
#ln -s $ROOTFS ./rootfs.img

mv bin/bvlc_googlenet.caffemodel.1.1.7201.GPU.FP16.engine networks/
mv bin/fcn_resnet18.onnx.1.1.7201.GPU.FP16.engine networks/
mv bin/ssd_mobilenet_v2_coco.uff.1.1.7201.GPU.FP16.engine networks/


echo "Running FC VM..."
${FC_BIN} --api-sock /tmp/fc.sock --config-file ${FC_CONFIG} --seccomp-level 0
