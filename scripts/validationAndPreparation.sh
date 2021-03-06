#!/bin/bash
#
# validates a submission and prepares next challenge

. /app/scripts/load_env_sshkey.sh
set -e

# reads newest contributions and stores its data in variables
NEWEST_CONTRIBUTION=`lftp sftp://"$SSH_USER":@"$SFTP_ADDRESS" -e "set sftp:connect-program \"ssh -a -x -o StrictHostKeyChecking=no -i $SSH_FILE_PATH\"; find -l | grep \"response$\" | sort -k4 | tail -1; bye"`
NEWEST_CONTRIBUTION_DATE=`echo "$NEWEST_CONTRIBUTION" | awk '{print $4 $5}' | sed 's/[^0-9]*//g'`
NEWEST_CONTRIBUTION_NAME=`echo "$NEWEST_CONTRIBUTION" | awk '{print $6}'`
NEWEST_CONTRIBUTION_NAME=${NEWEST_CONTRIBUTION_NAME:2}

# checks whether a new contribution was found
if [ $NEWEST_CONTRIBUTION_DATE -gt $THRESHOLD_DATE_FOR_FILE_ACCEPTANCE ]; then

	echo "current newest contribution is $NEWEST_CONTRIBUTION_NAME with the time $NEWEST_CONTRIBUTION_DATE"

	#safe date of newest contribution so that files are not verified twice
	THRESHOLD_DATE_FOR_FILE_ACCEPTANCE=$NEWEST_CONTRIBUTION_DATE #used for easy testing with source command
	sed -i "s/THRESHOLD_DATE_FOR_FILE_ACCEPTANCE=.*/THRESHOLD_DATE_FOR_FILE_ACCEPTANCE=$THRESHOLD_DATE_FOR_FILE_ACCEPTANCE/g" $DATABASE_FILE_PATH

	#If a new contribution is found, do verification and preparation for next round
	cd $CHALLENGE_WORKDIR
	echo "starting download; this could take a while..."
	$connect_to_sftp_server:$NEWEST_CONTRIBUTION_NAME $CHALLENGE_WORKDIR	

	echo "verifying the submission; this could take a while..."
	set +e

	# cargo run --release --bin verify_transform_constrained
   	/app/target/release/verify_transform_constrained
	if [ $? -eq 0 ]; then
		VERIFIED="true"
		echo Verification successful
	else
		VERIFIED="false"
		echo Verification failed
	fi
	set -e

	if [[ "$VERIFIED" = "true" ]]; then
		TIME=$(date +%s.%N)
		echo "uploading to ftp server and documentation; this could take a while..."
		mv new_challenge challenge
		mv response "response-$TRUSTED_SETUP_TURN-$TIME"

		#upload new challenge file for next candiate
		echo "put challenge" | $connect_to_sftp_server:$SFTP_CHALLENGE_PATH

		#document response from previous participant
		echo "put response-$TRUSTED_SETUP_TURN-$TIME" | $connect_to_sftp_server:$SFTP_ARCHIVE_PATH
		rm response-$TRUSTED_SETUP_TURN-$TIME

		#safe incremented variable Trusted_setup_turn for next execution
		TRUSTED_SETUP_TURN=$((TRUSTED_SETUP_TURN + 1)) #used for easy testing with source command
		sed -i "s/TRUSTED_SETUP_TURN=.*/TRUSTED_SETUP_TURN=$TRUSTED_SETUP_TURN/g" $DATABASE_FILE_PATH

		#document new challenge file
		cp challenge "challenge-$TRUSTED_SETUP_TURN-$TIME"
		echo "put challenge-$TRUSTED_SETUP_TURN-$TIME" | $connect_to_sftp_server:$SFTP_ARCHIVE_PATH
		rm challenge-$TRUSTED_SETUP_TURN-$TIME

		#Post a message in Gitter:
		MESSAGE="The submission of $NEWEST_CONTRIBUTION_NAME uploaded at $NEWEST_CONTRIBUTION_DATE was successful. The new challenge for the $TRUSTED_SETUP_TURN -th contributor has been uploaded. If you want to be the next contributor, let us know in the chat. Your challenge would be ready here: sftp://$SFTP_ADDRESS:$SFTP_CHALLENGE_PATH . The instructions for the computation can be found here: https://github.com/gnosis/powersoftau#instructions . Please also consider the process instructions described in here: https://docs.google.com/document/d/1a9EFrJkVX6DoqDA9uQNZF6Fdi9zoFeOJ78pc7vem-FA "
		. /app/scripts/send_msg_to_gitter.sh "$MESSAGE"
	else
		#Post a message in Gitter:
		MESSAGE="The submission of $NEWEST_CONTRIBUTION_NAME uploaded at $NEWEST_CONTRIBUTION_DATE was not successful." 
		. /app/scripts/send_msg_to_gitter.sh "$MESSAGE"
	fi
else
	echo "Newest contribution was created at $NEWEST_CONTRIBUTION_DATE and is not newer than $THRESHOLD_DATE_FOR_FILE_ACCEPTANCE"
fi
