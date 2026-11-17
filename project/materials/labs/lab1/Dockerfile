FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

ARG USER_NAME=x
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-multilib \
        gdb \
        git \
        ca-certificates \
        make \
        binutils \
        nasm \
        file \
        python3-six \
        sudo \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

#
# Create a real user matching the host UID/GID.
#
# Ubuntu may already contain UID/GID 1000, so reuse/rename
# existing entries instead of attempting to create duplicates.
#
RUN set -eux; \
    \
    if ! getent group "${GROUP_ID}" >/dev/null; then \
        groupadd --gid "${GROUP_ID}" "${USER_NAME}"; \
    fi; \
    \
    EXISTING_USER="$(getent passwd "${USER_ID}" | cut -d: -f1 || true)"; \
    \
    if [ -n "${EXISTING_USER}" ]; then \
        if [ "${EXISTING_USER}" != "${USER_NAME}" ]; then \
            usermod \
                --login "${USER_NAME}" \
                --home "/home/${USER_NAME}" \
                --move-home \
                --shell /bin/bash \
                "${EXISTING_USER}"; \
        fi; \
        usermod \
            --gid "${GROUP_ID}" \
            --shell /bin/bash \
            "${USER_NAME}"; \
    else \
        useradd \
            --uid "${USER_ID}" \
            --gid "${GROUP_ID}" \
            --create-home \
            --shell /bin/bash \
            "${USER_NAME}"; \
    fi; \
    \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USER_NAME}"; \
    chmod 0440 "/etc/sudoers.d/${USER_NAME}"

# Install PEDA.
RUN git clone --depth 1 https://github.com/longld/peda.git /opt/peda \
    && cp /usr/lib/python3/dist-packages/six.py /opt/peda/lib/six.py \
    && echo 'source /opt/peda/peda.py' > "/home/${USER_NAME}/.gdbinit" \
    && chown "${USER_ID}:${GROUP_ID}" "/home/${USER_NAME}/.gdbinit"

ENV HOME="/home/${USER_NAME}"
ENV PYTHONWARNINGS="ignore"

USER ${USER_ID}:${GROUP_ID}
WORKDIR /lab1

CMD ["/bin/bash"]
