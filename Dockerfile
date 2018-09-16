FROM ubuntu:18.04
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y lib32gcc1 lib32stdc++6 lib32tinfo5 curl jq
RUN useradd -m steam
USER steam
WORKDIR /home/steam

RUN curl -o steamcmd.tar.gz http://media.steampowered.com/installer/steamcmd_linux.tar.gz && \
    tar xzvf steamcmd.tar.gz && \
    rm steamcmd.tar.gz

RUN ./steamcmd.sh +login anonymous +force_install_dir gmod +app_update 4020 +quit

WORKDIR /home/steam/gmod/
COPY files/ ./

EXPOSE 27005/udp
EXPOSE 27015/udp

ENTRYPOINT ["./startup.sh"]
