FROM amd64/alpine
MAINTAINER bevice
RUN apk update && \
	apk upgrade && \
	apk add --no-cache make cmake curl ca-certificates wget bash python3 git openssh-client && \
	wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk && \
	apk add glibc-2.28-r0.apk && rm -f glibc-2.28-r0.apk
RUN curl -O https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 && \
	tar xf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 -C / && \
	rm -f gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
RUN curl -o /builder.sh https://raw.githubusercontent.com/bevice/cortextm-docker-builder/master/builder.sh && chmod +x /builder.sh
ENV ARM_TOOLCHAIN_PATH /gcc-arm-none-eabi-9-2019-q4-major
ENV PATH ${PATH}:/gcc-arm-none-eabi-9-2019-q4-major/bin
ENTRYPOINT /builder.sh