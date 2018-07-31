FROM ubuntu:latest

MAINTAINER Stefan Geissler<stefan.geissler@informatik.uni-wuerzburg.de>, Susanna Schwarzmann<susanna.schwarzmann@informatik.uni-wuerzburg.de>

RUN apt update && \
    apt install -y python python-pip ffmpeg bc && \
    pip install --upgrade pandas && \ 
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

ADD . /tmp/tools

VOLUME ["/videos"]

WORKDIR /tmp/tools

RUN chmod +x ./video_encode.sh

ENTRYPOINT ["./video_encode.sh"]

CMD ["./video_encode.sh"]

