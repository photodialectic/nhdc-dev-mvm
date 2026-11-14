# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ARG GO_VERSION=1.27.4
ARG NODE_VERSION=26.13.1
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# System packages: shell, editors, git, python, build tools, and common dev utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        git \
        tmux \
        vim-nox \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        unzip \
        less \
        ripgrep \
        openssh-client \
        sudo \
        jq \
        htop \
        tree \
        fd-find \
        bat \
        fzf \
        direnv \
        zsh \
        shellcheck \
        procps \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI + Docker CLI/Compose plugin (client only; talks to the host daemon via socket)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        gh docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Node.js (official tarball, checksum-verified)
RUN ARCH="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$ARCH" in \
        amd64|x86_64) NODE_ARCH=x64;    NODE_SHA=5c063e46bab0fbc1c17cc445d7ff129cbdcd0471be6ed83b6ab864f8143bc864 ;; \
        arm64|aarch64) NODE_ARCH=arm64; NODE_SHA=89e1853138db51e8b82d3e98ba9c0d3f2956a28e5e55ea1b7e12d25aae92d5dd ;; \
        *) echo "unsupported arch $ARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
    && echo "${NODE_SHA}  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz

# Go (official tarball, arch-aware, checksum-verified)
RUN ARCH="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$ARCH" in \
        amd64|x86_64) GOARCH=amd64; GO_SHA=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840 ;; \
        arm64|aarch64) GOARCH=arm64; GO_SHA=3392582988a273a87ab5043ee1b2c9c17a2c3c00580bf9326c47a2e0aaaeac92 ;; \
        *) echo "unsupported arch $ARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" -o /tmp/go.tar.gz \
    && echo "${GO_SHA}  /tmp/go.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

# hadolint (checksum-verified)
RUN ARCH="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$ARCH" in \
        amd64|x86_64) HADOLINT_ARCH=x86_64; HADOLINT_SHA=c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507 ;; \
        arm64|aarch64) HADOLINT_ARCH=arm64;  HADOLINT_SHA=f6198ef8090f404dbb771abfee086eb8c48ac177f30da7fd3510aca35b344b5d ;; \
        *) echo "unsupported arch $ARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v2.15.1/hadolint-linux-${HADOLINT_ARCH}" -o /usr/local/bin/hadolint \
    && echo "${HADOLINT_SHA}  /usr/local/bin/hadolint" | sha256sum -c - \
    && chmod +x /usr/local/bin/hadolint

# Global Node packages (pinned; bump versions here to taste)
RUN npm install -g \
        typescript@7.0.2 \
        ts-node@10.9.2 \
        eslint@10.15.0 \
        prettier@3.10.1 \
        npm-check-updates@23.1.1 \
        pnpm@12.18.0 \
        yarn@1.22.22

# Python tooling in an isolated venv (avoids PEP 668 "externally managed" errors)
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir ipython black ruff

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Git prompt for all users (login shells source /etc/profile.d automatically)
RUN printf '%s\n' \
    'source /usr/lib/git-core/git-sh-prompt' \
    'PS1='"'"'\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)")\$ '"'"'' \
    > /etc/profile.d/git-prompt.sh

# Non-root user (UID 1000 to match a typical host user for bind mounts)
RUN groupadd --gid 1000 dev \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# User-level tooling (installed into the dev user's home)
USER dev
ENV HOME=/home/dev \
    GOPATH=/home/dev/go \
    PATH="/usr/local/go/bin:/home/dev/go/bin:${PATH}"

RUN curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Source the shared git prompt in non-login shells too
RUN echo 'source /etc/profile.d/git-prompt.sh' >> "$HOME/.bashrc" \
    && echo 'source /etc/profile.d/git-prompt.sh' >> "$HOME/.zshrc"

RUN git clone https://github.com/photodialectic/tilde.git "$HOME/.tilde" \
    && cd "$HOME/.tilde" && SKIP_VIM_PLUGINS=1 make install

WORKDIR /workspace
CMD ["bash"]
