FROM rust:1.33-slim
MAINTAINER alex@gnosis.pm

WORKDIR /app

# Install system libs
RUN apt-get update && apt-get install -y --no-install-recommends \
 				lftp \
				curl \
				openssh-server

RUN rm -rf /var/lib/apt/lists/*

# Copy project files into Docker
COPY . .

#PID file for storage of cron-pids
#and create config file for validation script
#and create .ssh folder for storage of ssh keys
RUN touch /root/forever.pid \
	&& mkdir /app/config \
	&& mkdir /root/.ssh

# Build project
RUN sh scripts/build_all.sh

# Signal handling for PID1 https://github.com/krallin/tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

#support for sftp
EXPOSE 22

# Run the command on container startup
ENTRYPOINT ["/tini", "--"]
