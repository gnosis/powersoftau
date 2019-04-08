FROM rust:1.33
MAINTAINER alex@gnosis.pm

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
				cron \
 				lftp \
				nano \
				xxd

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml  ./
#RUN mkdir src && touch src/lib.rs && cargo build

COPY src/. src/.
COPY test/. test/.

#support for sftp
EXPOSE 22

#PID file for storage of cron-pids
#and create config file for validation script
#and create .ssh folder for storage of ssh keys
RUN touch /root/forever.pid \
	&& mkdir /app/config \
	&& mkdir /root/.ssh

# Add crontab file in the cron directory
ADD tasks/cron-task /etc/cron.d/hello-cron

# Give execution rights on the cron job
# and pply cron job
# and create the log file to be able to run tail
RUN chmod 0644 /etc/cron.d/hello-cron \
	&& crontab /etc/cron.d/hello-cron \
	&& touch /var/log/cron.log

#Copy env variables folder for cron job
COPY variables.sh ./

#COPY scripts to docker
COPY scripts/. scripts/.

RUN sh scripts/build_all.sh

# Run the command on container startup
CMD ["cron", "-f"]
