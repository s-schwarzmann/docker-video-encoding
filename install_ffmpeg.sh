#!/bin/bash

#unzip ffmpeg folder 
unzip ffmpeg.zip

wget https://github.com/Netflix/vmaf/archive/v1.3.4.tar.gz
tar -xf v1.3.4.tar.gz
cd vmaf-1.3.4

cd ptools; make; cd ../wrapper; make; cd ..;
make install


# Bash script to install latest version of ffmpeg and its dependencies on Ubuntu 16.04
# Inspired from https://gist.github.com/faleev/3435377

# Remove any existing packages:
apt -y remove ffmpeg x264 libav-tools libvpx-dev libx264-dev

# Get the dependencies (Ubuntu Server or headless users):
apt update
apt -y install autoconf automake build-essential libass-dev libfreetype6-dev \
  git libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texinfo wget zlib1g-dev


mkdir ffmpeg_sources

# Install Yasm:
# An assembler for x86 optimizations used by x264 and FFmpeg. Highly recommended or your resulting build may be very slow.
cd ffmpeg_sources
wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install
cd ..

# Install nasm:
# NASM assembler. Required for compilation of x264 and other tools.
wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.bz2
tar xjvf nasm-2.13.01.tar.bz2
cd nasm-2.13.01
./autogen.sh
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
PATH="$HOME/bin:$PATH" make
make install
cd ..

# Install libx264:
apt -y install libx264-dev
wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
tar xjvf last_x264.tar.bz2
cd x264-snapshot*
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-opencl
PATH="$HOME/bin:$PATH" make
make install
checkinstall --pkgname=x264 --pkgversion="3:$(./version.sh | \
  awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes \
    --fstrans=no --default
cd ..

# Install libx265-dev:
apt-get install libx265-dev
#Otherwise you can compile:

#apt-get install cmake mercurial
#hg clone https://bitbucket.org/multicoreware/x265
#cd x265/build/linux
#PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
#make
#make install

#cd ../../..

# Install libfdk-aac AAC audio decoder
apt install libfdk-aac-dev
wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
tar xzvf fdk-aac.tar.gz
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install

cd ..

# Install libmp3lame MP3 audio encoder .
apt install libmp3lame-dev
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --disable-shared
make
make install

cd ..

# Install libopus opus audio decoder and encoder.
apt install libopus-dev

wget https://archive.mozilla.org/pub/opus/opus-1.1.5.tar.gz
tar xzvf opus-1.1.5.tar.gz
cd opus-1.1.5
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
cd ..

# Install libvpx VP8/VP9 video encoder and decoder.
apt install libvpx-dev
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests
PATH="$HOME/bin:$PATH" make
make install
cd ..


# Add lavf support to x264
# This allows x264 to accept just about any input that FFmpeg can handle and is useful if you want to use x264 directly. See a more detailed explanation of what this means.
#cd ~/x264
#make distclean
#./configure --enable-static
#make
#checkinstall --pkgname=x264 --pkgversion="3:$(./version.sh | \
#  awk -F'[" ]' '/POINT/{print $4"+git"$5}')" --backup=no --deldoc=yes \
#  --fstrans=no --default

# Installing FFmpeg
#git clone --depth 1 git://source.ffmpeg.org/ffmpeg
#cd ffmpeg
#./configure --enable-gpl --enable-libfaac --enable-libmp3lame --enable-libopencore-amrnb \
#  --enable-libopencore-amrwb --enable-librtmp --enable-libtheora --enable-libvorbis \
#    --enable-libvpx --enable-libx264 --enable-nonfree --enable-version3 
#make
#checkinstall --pkgname=ffmpeg --pkgversion="5:$(date +%Y%m%d%H%M)-git" --backup=no \
#  --deldoc=yes --fstrans=no --default
#  hash x264 ffmpeg ffplay ffprobe
 
# cd ..

# Optional: install qt-faststart
# This is a useful tool if you're showing your H.264 in MP4 videos on the web. It relocates some data in the video to allow playback to begin before the file is completely downloaded. Usage: qt-faststart input.mp4 output.mp4.
#cd ~/ffmpeg
#make tools/qt-faststart
#checkinstall --pkgname=qt-faststart --pkgversion="$(date +%Y%m%d%H%M)-git" --backup=no \
#  --deldoc=yes --fstrans=no --default install -Dm755 tools/qt-faststart \
#  /usr/local/bin/qt-faststart

wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree \
  --enable-version3 \
  --enable-libvmaf
PATH="$HOME/bin:$PATH" make
make install
hash -r

export PATH="$HOME/bin:$PATH"
echo "PATH=\"$HOME/bin:$PATH\"" > ~/.bashrc
