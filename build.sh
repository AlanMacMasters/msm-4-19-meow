#!/bin/bash
export RDIR="$(pwd)"

read -p "Enter Kernel name: " KERNEL_NAME

# clang-r510928
if [ ! -d "${RDIR}/toolchains/clang-r510928" ]; then
    mkdir -p "${RDIR}/toolchains/clang-r510928" && cd "${RDIR}/toolchains/clang-r510928"
    ( wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/android-14.0.0_r33/clang-r510928.tar.gz && \
      tar -xvf clang-r510928.tar.gz && rm clang-r510928.tar.gz  
    )
fi

# tc paths
LLVM_PATH="${RDIR}/toolchains/clang-r510928/bin"
GCC_PATH="${RDIR}/toolchains/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu/bin"

# export clang path
export PATH="${LLVM_PATH}":$PATH

# define build variables
export ARGS="
-C $(pwd) \
O=$(pwd)/out \
-j$(nproc) \
ARCH=arm64 \
LLVM=1 \
LLVM_IAS=1 \
CC=${LLVM_PATH}/clang \
CROSS_COMPILE=${GCC_PATH}/aarch64-none-linux-gnu- \
DTC_EXT=$(pwd)/tools/dtc \
CONFIG_BUILD_ARM64_DT_OVERLAY=y \
"

# main compilation process
DATE_START=$(date +"%s")
make ${ARGS} r8q_defconfig
make ${ARGS} menuconfig
make ${ARGS} Image.gz || exit 1
make ${ARGS} dtbs

DTB_OUT="out/arch/arm64/boot/dts/vendor/qcom"
IMAGE="out/arch/arm64/boot/Image.gz"

cat $DTB_OUT/*.dtb > AnyKernel3/dtb

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Compile time: $(($DIFF / 60)) minutes(s) and $(($DIFF % 60)) seconds."

# zipping stuffs
cp $IMAGE AnyKernel3/Image.gz
cd AnyKernel3
rm *.zip
zip -r9 ${KERNEL_NAME}-.zip .
