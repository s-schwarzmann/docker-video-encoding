FROM ubuntu:16.04

MAINTAINER Stefan Geissler<stefan.geissler@informatik.uni-wuerzburg.de>, Susanna Schwarzmann<susanna.schwarzmann@informatik.uni-wuerzburg.de>

RUN apt update && apt install -y python python-pip bc autoconf automake build-essential libass-dev libfreetype6-dev \
  git libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texinfo wget zlib1g-dev libx265-dev=1.9-3 && pip install --upgrade pandas && rm -rf /var/lib/apt/lists/*


ADD . /tmp/tools

WORKDIR /tmp/tools

RUN chmod +x ./video_encode.sh

CMD ["bash", "-c", "PATH=$PATH:/tmp/tools/ffmpeg ./video_encode.sh $VID $CRF $MINDUR $MAXDUR $SEGLEN"]

