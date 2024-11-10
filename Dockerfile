FROM debian:bookworm

ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG LOCALE=ja_JP.UTF-8
ARG TIME_ZONE=Asia/Tokyo

ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV TZ=${TIME_ZONE}
ENV DEBIAN_FRONTEND=noninteractive

# Install development tools and utilities
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    chromium \
    curl \
    dnsutils \
    fonts-ipafont \
    git \
    gnupg \
    imagemagick \
    jq \
    less \
    libssl-dev \
    locales \
    mariadb-client \
    ncdu \
    openssh-client \
    postgresql-client \
    rsync \
    shellcheck \
    sqlite3 \
    sudo \
    tree \
    unzip \
    wget \
    vim \
    yq \
    zip \
    zsh \
    # clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Configure locale, create user, and set up workspace
RUN : \
    # locale
    && sed -i -E "s/# (${LOCALE})/\1/" /etc/locale.gen \
    && locale-gen ${LOCALE} \
    # user
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    # work directory
    && mkdir -p /workspace \
    && chown ${USERNAME}:${USERNAME} /workspace

# Install Oh My Zsh and set as default shell
RUN su ${USERNAME} -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
    && chsh -s /usr/bin/zsh ${USERNAME}

# Install Oh My Zsh plugins
ENV OH_MY_ZSH_DIR=/home/${USERNAME}/.oh-my-zsh
RUN : \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${OH_MY_ZSH_DIR}/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${OH_MY_ZSH_DIR}/custom/plugins/zsh-syntax-highlighting \
    && git clone https://github.com/zsh-users/zsh-completions ${OH_MY_ZSH_DIR}/custom/plugins/zsh-completions \
    && git clone https://github.com/marlonrichert/zsh-autocomplete.git ${OH_MY_ZSH_DIR}/custom/plugins/zsh-autocomplete \
    && chown -R ${USERNAME}:${USERNAME} ${OH_MY_ZSH_DIR}/custom/plugins

# Configure Zsh
RUN echo '' > /home/${USERNAME}/.zshrc \
    && echo 'export ZSH=~/.oh-my-zsh' >> /home/${USERNAME}/.zshrc \
    && echo 'ZSH_THEME="robbyrussell"' >> /home/${USERNAME}/.zshrc \
    && echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#999999"' >> /home/${USERNAME}/.zshrc \
    && echo 'ZSH_AUTOSUGGEST_STRATEGY=(history completion)' >> /home/${USERNAME}/.zshrc \
    && echo 'plugins=(git docker composer zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-autocomplete)' >> /home/${USERNAME}/.zshrc \
    && echo 'source $ZSH/oh-my-zsh.sh' >> /home/${USERNAME}/.zshrc \
    && echo 'autoload -U compinit && compinit' >> /home/${USERNAME}/.zshrc \
    && echo 'zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"' >> /home/${USERNAME}/.zshrc \
    && echo 'setopt HIST_IGNORE_DUPS' >> /home/${USERNAME}/.zshrc \
    && echo 'setopt HIST_IGNORE_SPACE' >> /home/${USERNAME}/.zshrc \
    && echo 'setopt HIST_REDUCE_BLANKS' >> /home/${USERNAME}/.zshrc \
    && echo 'setopt AUTO_CD' >> /home/${USERNAME}/.zshrc \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.zshrc

# Install and configure NVM (Node Version Manager)
ENV NVM_DIR=/home/${USERNAME}/.nvm
RUN mkdir -p ${NVM_DIR} \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && chown -R ${USERNAME}:${USERNAME} ${NVM_DIR} \
    # Add nvm configuration
    && echo 'export NVM_DIR="$HOME/.nvm"' >> /home/${USERNAME}/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/${USERNAME}/.zshrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/${USERNAME}/.zshrc

# Set working directory
WORKDIR /workspace

# Start Zsh
CMD ["zsh"]
