FROM ubuntu:16.04

MAINTAINER Stefan Geissler<stefan.geissler@informatik.uni-wuerzburg.de>, Susanna Schwarzmann<susanna.schwarzmann@informatik.uni-wuerzburg.de>

# Install dependencies
RUN apt update && \
    apt install -y unzip python python-pip bc autoconf automake build-essential libass-dev libfreetype6-dev \
                   git libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
                   libxcb-xfixes0-dev pkg-config texinfo wget zlib1g-dev libx265-dev=1.9-3 && \
    pip install --upgrade pandas && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Install Netflix VMAF
RUN wget https://github.com/Netflix/vmaf/archive/v1.3.9.tar.gz && \
    tar -xf v1.3.9.tar.gz && \
    cd vmaf-1.3.9 && \
    cd ptools; make; cd .. && \
    cd wrapper; make; cd .. && \
    make install && \
    cd ..; rm -rf vmaf-1.3.9/; rm -f v1.3.9.tar.gz

COPY install_ffmpeg.sh install_ffmpeg.sh

RUN chmod +x ./install_ffmpeg.sh && ./install_ffmpeg.sh

WORKDIR /tools

# Add the (relevant) git content
COPY scripts/ /tools/scripts
COPY video_encode.sh /tools/

# Fix permissions
RUN chmod o+r+w /tools && \
    chmod +x ./video_encode.sh

VOLUME ["/videos", "/results", "/tmpdir"]

ENTRYPOINT ["./video_encode.sh"]

