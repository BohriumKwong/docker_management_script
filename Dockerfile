#########################################################
# base
#########################################################

FROM ubuntu:bionic

# 设定DNS和源
COPY sources.list /etc/apt/sources.list

# 替换conda源为清华源
COPY .condarc /root/.condarc

# APT安装基本包
# 需要 perl 安装 cuda
# opencv 需要 libsm0
RUN export DEBIAN_FRONTEND=noninteractive \
	&& export DEBCONF_NONINTERACTIVE_SEEN=true \
	&& echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections \
	&& echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections \
	&& apt update \
	&& apt install -y perl gcc g++ make libglu1-mesa-dev libopengl0 libglx-mesa0 sudo vim psmisc ssh net-tools gnupg curl ca-certificates patch git \
	&& apt clean

# 设定cuda环境
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf &&     echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_REQUIRE_CUDA=cuda>=9.0

ENV BASE_INSTALL=base_install

# 复制待安装文件
COPY $BASE_INSTALL/ /$BASE_INSTALL/

# 安装cuda和python
RUN chmod +x -R /$BASE_INSTALL \
	&& /$BASE_INSTALL/cuda_9.0.176_384.81_linux.run --silent --toolkit --override --no-opengl-libs \
	&& /$BASE_INSTALL/cuda_9.0.176.1_linux.run --silent --accept-eula \
	&& /$BASE_INSTALL/cuda_9.0.176.2_linux.run --silent --accept-eula \
	&& /$BASE_INSTALL/cuda_9.0.176.3_linux.run --silent --accept-eula \
	&& /$BASE_INSTALL/cuda_9.0.176.4_linux.run --silent --accept-eula \
	&& /$BASE_INSTALL/Anaconda3-5.2.0-Linux-x86_64.sh -b \
	&& echo \
	&& echo . /root/anaconda3/bin/activate >> /root/.bashrc \
	&& /root/anaconda3/bin/pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装cudnn
RUN tar xvf /$BASE_INSTALL/cudnn-9.0-linux-x64-v7.6.5.32.tgz -C /$BASE_INSTALL \
	&& cp -rf /$BASE_INSTALL/cuda/* /usr/local/cuda \
	&& rm -r /$BASE_INSTALL/cuda


#########################################################
# extra
#########################################################

ENV EXTRA_INSTALL=extra_install

COPY $EXTRA_INSTALL/ /$EXTRA_INSTALL/
RUN chmod +x -R /$EXTRA_INSTALL

# 添加novnc，已处理不需要再联网下载websock
RUN tar xvf /$EXTRA_INSTALL/novnc.tar.gz -C /

# 安装桌面和VNC
RUN export DEBIAN_FRONTEND=noninteractive \
	&& export DEBCONF_NONINTERACTIVE_SEEN=true \
	&& apt update \
	; apt install -y -f lxqt || apt install -y -f lxqt \
	; apt install -y lightdm openbox keyboard-configuration || apt install -y lightdm openbox keyboard-configuration \
	; apt install -y --no-install-recommends xvfb x11vnc vnc4server \
	&& apt install -y --no-install-recommends terminator \
	&& apt clean

# 容器开启时启动
COPY startup.sh /startup.sh
RUN chmod 555 /startup.sh

# 入口
CMD ["/startup.sh"]

# 安装 pycharm 和 vscode
RUN export DEBIAN_FRONTEND=noninteractive \
	&& export DEBCONF_NONINTERACTIVE_SEEN=true \
	&& apt update \
	&& apt install -y --no-install-recommends libnotify4 libnss3 libsecret-1-0 \
	&& apt clean

RUN tar xvf /$EXTRA_INSTALL/pycharm-community-2019.3.tar.gz -C /root \
	&& dpkg -i /$EXTRA_INSTALL/code_1.41.0-1576089540_amd64.deb

# 安装更好的文件管理器
RUN apt update \
	&& apt install -y nautilus \
	&& apt clean

# 解决dbus错误问题
RUN echo eval \`dbus-launch --sh-syntax\` >> /root/.bashrc

# 安装python包
RUN /root/anaconda3/bin/pip install /$EXTRA_INSTALL/torch-1.1.0-cp36-cp36m-linux_x86_64.whl


#########################################################
# extra2
#########################################################

# 安装更多python包
COPY requirements.txt /extra_install2/requirements.txt
RUN /root/anaconda3/bin/pip install -r /extra_install2/requirements.txt

# 添加中文支持
RUN apt update \
	&& apt install -y language-pack-zh-hans locales \
	&& echo >> /etc/environment \
	&& echo LANG="zh_CN.UTF-8" >> /etc/environment \
	&& echo LANGUAGE="zh_CN:zh:en_US:en" >> /etc/environment \
	&& echo LC_ALL="zh_CN.UTF-8" >> /etc/environment \
	&& echo >> /root/.bashrc \
	&& echo export LANG="zh_CN.UTF-8" >> /root/.bashrc \
	&& echo export LANGUAGE="zh_CN:zh:en_US:en" >> /root/.bashrc \
	&& echo export LC_ALL="zh_CN.UTF-8" >> /root/.bashrc \
	&& locale-gen en_US.UTF-8 \
	&& locale-gen zh_CN.UTF-8 \
	&& locale-gen zh_CN.GBK \
	&& apt-get install -y fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming \
	&& apt clean \
	&& /usr/bin/mkfontscale \
	&& /usr/bin/mkfontdir \
	&& /usr/bin/fc-cache -fv

# extra2 包安装
ENV EXTRA_INSTALL2=extra_install2

COPY $EXTRA_INSTALL2/ /$EXTRA_INSTALL2/
RUN chmod +x -R /$EXTRA_INSTALL2

# 安装sougou拼音
RUN apt update \
	&& apt install -y fcitx \
	; dpkg -i $EXTRA_INSTALL2/sogoupinyin_2.3.1.0112_amd64.deb \
	|| apt install -f -y \
	&& apt clean

# 安装谷歌浏览器
RUN apt update \
	&& apt install -y chromium-browser \
	&& apt clean

# 启动fcitx和搜狗拼音
RUN sogou-diag; sogou-qimpanel; fcitx;
