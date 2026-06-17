FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    gfortran \
    ca-certificates \
    bash \
    findutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# RTKLIB Explorer demo5 branch
RUN git clone \
    --depth 1 \
    --branch demo5 \
    https://github.com/rtklibexplorer/RTKLIB.git


# ============================================================
# Build convbin
# ============================================================

WORKDIR /opt/RTKLIB/app/consapp/convbin/gcc

RUN set -eux; \
    if [ -f Makefile ] || [ -f makefile ]; then \
        make; \
    else \
        echo "No Makefile found in $(pwd)"; \
        find /opt/RTKLIB/app -maxdepth 6 \
            \( -iname 'makefile' -o -iname 'Makefile' \) \
            -print; \
        exit 1; \
    fi

RUN set -eux; \
    if [ -x ./convbin ]; then \
        install -m 0755 ./convbin /usr/local/bin/convbin; \
    elif [ -x /opt/RTKLIB/bin/convbin ]; then \
        install -m 0755 \
            /opt/RTKLIB/bin/convbin \
            /usr/local/bin/convbin; \
    elif [ -x /opt/RTKLIB/app/consapp/convbin/gcc/convbin ]; then \
        install -m 0755 \
            /opt/RTKLIB/app/consapp/convbin/gcc/convbin \
            /usr/local/bin/convbin; \
    else \
        echo "convbin binary was not found"; \
        find /opt/RTKLIB -name convbin -type f -print; \
        exit 1; \
    fi; \
    convbin -h | head -n 20 || true


# ============================================================
# Build rnx2rtkp
# ============================================================

WORKDIR /opt/RTKLIB/app/consapp/rnx2rtkp/gcc

RUN set -eux; \
    if [ -f Makefile ] || [ -f makefile ]; then \
        make; \
    else \
        echo "No Makefile found in $(pwd)"; \
        find /opt/RTKLIB/app -maxdepth 6 \
            \( -iname 'makefile' -o -iname 'Makefile' \) \
            -print; \
        exit 1; \
    fi

RUN set -eux; \
    if [ -x ./rnx2rtkp ]; then \
        install -m 0755 ./rnx2rtkp /usr/local/bin/rnx2rtkp; \
    elif [ -x /opt/RTKLIB/bin/rnx2rtkp ]; then \
        install -m 0755 \
            /opt/RTKLIB/bin/rnx2rtkp \
            /usr/local/bin/rnx2rtkp; \
    elif [ -x /opt/RTKLIB/app/consapp/rnx2rtkp/gcc/rnx2rtkp ]; then \
        install -m 0755 \
            /opt/RTKLIB/app/consapp/rnx2rtkp/gcc/rnx2rtkp \
            /usr/local/bin/rnx2rtkp; \
    else \
        echo "rnx2rtkp binary was not found"; \
        find /opt/RTKLIB -name rnx2rtkp -type f -print; \
        exit 1; \
    fi; \
    rnx2rtkp -h 2>&1 | head -n 30 || true


# ============================================================
# Verify installed binaries
# ============================================================

RUN set -eux; \
    command -v convbin; \
    command -v rnx2rtkp; \
    ls -l /usr/local/bin/convbin; \
    ls -l /usr/local/bin/rnx2rtkp


# ============================================================
# Runtime settings
# ============================================================

WORKDIR /work

COPY convert_sbf_all.sh /usr/local/bin/convert_sbf_all.sh

RUN chmod +x /usr/local/bin/convert_sbf_all.sh

ENTRYPOINT ["/usr/local/bin/convert_sbf_all.sh"]
