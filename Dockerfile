FROM rust:latest
MAINTAINER alex@gnosis.pm

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

RUN apt-get update && apt-get -y install cron \
 				lftp \
				nano 

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml  ./
RUN mkdir src && touch src/lib.rs && cargo build
RUN cargo build

COPY src/. src/.
COPY scripts/. scripts/.
COPY test/. test/.

#support for sftp
EXPOSE 22


#create config file for validation script
RUN mkdir /app/config


# Add crontab file in the cron directory
ADD tasks/cron-task /etc/cron.d/hello-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/hello-cron

# Apply cron job
RUN crontab /etc/cron.d/hello-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD ["cron", "-f"]

