# The commands in this file all run as 'root', whereas the container user is 'vscode'. That means
# most automatic configuration attempted by the tools is applied to the wrong user, and thus will
# be lost. Most people do not connect to a development container as 'root'.
#
# As it turns out, this suits us just fine, since we don't like the way most tools try to configure
# themselves, and we prefer to do that oursevles; we have our own approach. But the disconnect
# should be noted, and there are some subtle challenges that arise from this, including settting
# ownership correctly on some installed files (see `chown` below).
#
# Changing the user to 'vscode' during installation would present its own challenges, and tends to
# be discouraged in Docker lore. It takes a lot of work to get either approach right.

FROM mcr.microsoft.com/devcontainers/base:ubuntu
ENV PYTHON_VERSION=3.12.9
ENV NODE_VERSION=v22.14.0
ENV PNPM_VERSION=9.15.8
ENV POETRY_VERSION=2.1.2

# Various packages, including tools and libraries needed to build things from source.
# While this is sometimes necessary, at the moment we're not building anything from source here.
RUN export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get -y install --no-install-recommends \
	curl wget git sudo jq nano man \
	make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
	xz-utils tk-dev libffi-dev liblzma-dev libxml2-dev libxmlsec1-dev \
	libsqlite3-dev libncurses5-dev libncursesw5-dev \
	rsync graphviz dnsutils gettext sqlite3 sqlite3-doc && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python using uv. Blink and you'll miss it. See https://docs.astral.sh/uv/ for details.
ENV XDG_HOME=/home/vscode/.local
ENV XDG_BIN_HOME=/home/vscode/.local/bin
ENV XDG_DATA_HOME=/home/vscode/.local/share
ENV WORKSPACE_PYTHON_DIR=/home/vscode/.local/share/python
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL=${XDG_BIN_HOME} sh && \
	${XDG_BIN_HOME}/uv python install ${PYTHON_VERSION} && \
	${XDG_BIN_HOME}/uv venv ${WORKSPACE_PYTHON_DIR} && \
	${XDG_BIN_HOME}/uv pip install --python ${WORKSPACE_PYTHON_DIR} --upgrade pip setuptools wheel \
	tomlkit mypy pylint black pytest deepmerge pyYAML types-PyYAML && \
	chown -R vscode:vscode ${XDG_HOME} && \
	rm -rf /tmp/* /var/tmp/*

# Install Poetry. See https://python-poetry.org/docs/ for details.
ENV POETRY_HOME=/home/vscode/.local/share/poetry
RUN mkdir -p ${POETRY_HOME} && \
	${XDG_BIN_HOME}/uv venv ${POETRY_HOME} && \
	${XDG_BIN_HOME}/uv pip install --python ${POETRY_HOME} --upgrade pip setuptools && \
	${XDG_BIN_HOME}/uv pip install --python ${POETRY_HOME} poetry==${POETRY_VERSION} && \
	${POETRY_HOME}/bin/poetry self add poetry-plugin-export && \
	chown -R vscode:vscode ${POETRY_HOME} && \
	rm -rf /tmp/* /var/tmp/*

# Install nvm, node, npm, and pnpm, as sanely as possible.
ENV NVM_DIR=/home/vscode/.nvm
ENV NVM_BIN=${NVM_DIR}/versions/node/${NODE_VERSION}/bin
ENV PNPM_HOME=/home/vscode/.local/share/pnpm
RUN mkdir -p ${NVM_DIR} && \
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
	. ${NVM_DIR}/nvm.sh && \
	nvm install ${NODE_VERSION} && \
	wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash - && \
	mkdir -p /home/vscode/.config/pnpm && \
	echo 'store-dir=${PNPM_STORE_DIR}' >/home/vscode/.config/pnpm/rc && \
	chown -R vscode:vscode ${NVM_DIR} && \
	chown -R vscode:vscode ${PNPM_HOME} && \
	chown -R vscode:vscode /home/vscode/.config/pnpm && \
	rm -rf /tmp/* /var/tmp/*

# Install Google Cloud SDK and Cloud Storage FUSE.
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
	export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s` && \
	echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
	echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get -y install --no-install-recommends google-cloud-sdk fuse gcsfuse && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Google Cloud SQL Proxy. See https://cloud.google.com/sql/docs/postgres/connect-auth-proxy.
RUN curl -s "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.15.2/cloud-sql-proxy.linux.amd64" \
	-o /usr/local/bin/cloud-sql-proxy && \
	chmod +x /usr/local/bin/cloud-sql-proxy

# Install Postgres client.
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
	export POSTGRES_REPO=`lsb_release -c -s`-pgdg && \
	echo "deb http://apt.postgresql.org/pub/repos/apt $POSTGRES_REPO main" | tee /etc/apt/sources.list.d/pgdg.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get -y install --no-install-recommends postgresql-client && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Modify .bashrc. The script is not here--it must be present in the workspace for this to have any effect.
RUN echo "source scripts/bash-include" >>/home/vscode/.bashrc
