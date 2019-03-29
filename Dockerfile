FROM rust:latest
<<<<<<< HEAD
MAINTAINER alex@gnosis.pm

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

RUN apt-get update && apt-get -y install cron
RUN apt-get -y install lftp
RUN apt-get -y install nano

WORKDIR /app

COPY src/. src/.
COPY Cargo.toml .
COPY Cargo.lock .
RUN cargo build

#support for sftp
EXPOSE 22

COPY scripts/. scripts/.

#create config file for validation script
RUN mkdir /app/config
RUN echo '1' > /app/config/lastestContributionDate.txt
RUN echo '1' > /app/config/lastestContributionTurn.txt


# Add crontab file in the cron directory
ADD tasks/cron-task /etc/cron.d/hello-cron
=======
COPY . /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    nano \
    sudo \
    sftp \
    lftp  

COPY tasks/cron-task /etc/crontabs/root

RUN apt-get update && apt-get -y install cron

# Add crontab file in the cron directory
ADD crontab /etc/cron.d/hello-cron
>>>>>>> master

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/hello-cron

# Apply cron job
RUN crontab /etc/cron.d/hello-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
<<<<<<< HEAD
CMD ["cron", "-f"]
=======
CMD cron && tail -f /var/log/cron.log
>>>>>>> master
