# CHIA BUILD STEP
FROM python:3.9 AS chia_build

ARG BRANCH=latest
ARG COMMIT=""

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        lsb-release sudo

WORKDIR /chia-blockchain

RUN echo "cloning ${BRANCH}" && \
    git clone --branch ${BRANCH} --recurse-submodules=mozilla-ca https://github.com/Chia-Network/chia-blockchain.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "$COMMIT" ] && git checkout $COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh ./install.sh

# IMAGE BUILD
FROM python:3.9-slim

STOPSIGNAL SIGTERM
EXPOSE 8555
EXPOSE 8444

ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="generate"
ENV keys_passphrase=""
ENV keys_tmp="/tmp/mnemonic"
ENV harvester="false"
ENV farmer="false"
ENV node_farmer_and_wallet="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV TZ="UTC"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y sudo tzdata curl && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY --from=chia_build /chia-blockchain /chia-blockchain

ENV PATH=/chia-blockchain/venv/bin:$PATH
WORKDIR /chia-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
RUN ["chmod", "+x", "/usr/local/bin/docker-start.sh"]
RUN ["chmod", "+x", "/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
