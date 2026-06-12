FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    ca-certificates \
    bash \
    findutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# RTKLIB explorer demo5 branch
RUN git clone --depth 1 --branch demo5 https://github.com/rtklibexplorer/RTKLIB.git

# Correct path for the command-line converter convbin
WORKDIR /opt/RTKLIB/app/consapp/convbin/gcc

# Some RTKLIB trees use Makefile, some use makefile; this handles both.
RUN set -eux; \
    if [ -f Makefile ] || [ -f makefile ]; then \
        make; \
    else \
        echo "No Makefile found in $(pwd)"; \
        find /opt/RTKLIB/app -maxdepth 5 -iname 'makefile' -o -iname 'Makefile'; \
        exit 1; \
    fi

# Install convbin from the location where the RTKLIB makefile created it.
RUN set -eux; \
    if [ -x ./convbin ]; then \
        install -m 0755 ./convbin /usr/local/bin/convbin; \
    elif [ -x /opt/RTKLIB/bin/convbin ]; then \
        install -m 0755 /opt/RTKLIB/bin/convbin /usr/local/bin/convbin; \
    elif [ -x /opt/RTKLIB/app/consapp/convbin/gcc/convbin ]; then \
        install -m 0755 /opt/RTKLIB/app/consapp/convbin/gcc/convbin /usr/local/bin/convbin; \
    else \
        echo "convbin binary was not found"; \
        find /opt/RTKLIB -name convbin -type f -print; \
        exit 1; \
    fi; \
    convbin -h | head -n 20 || true

WORKDIR /work

COPY convert_sbf_all.sh /usr/local/bin/convert_sbf_all.sh
RUN chmod +x /usr/local/bin/convert_sbf_all.sh

ENTRYPOINT ["/usr/local/bin/convert_sbf_all.sh"]
