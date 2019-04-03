#!/bin/bash
connect_to_sftp_server="sftp -i /root/.ssh/$SSH_FILE $SSH_USER@trusted-setup.staging.gnosisdev.com"

if [[ -z "${DATE_OF_NEWEST_CONTRIBUTION}" ]]; then
  DATE_OF_NEWEST_CONTRIBUTION=1
fi

if [[ -z "${TRUSTED_SETUP_TURN}" ]]; then
  TRUSTED_SETUP_TURN=1
fi

set -e 

NEWEST_CONTRIBUTION=`lftp sftp://"$SSH_USER":@trusted-setup.staging.gnosisdev.com -e "set sftp:connect-program \"ssh -a -x -i ~/.ssh/$SSH_FILE\"; find -l | grep \"response$\" | sort -k4 | tail -1; bye"`
NEWEST_CONTRIBUTION_DATE=`echo "$NEWEST_CONTRIBUTION" | awk '{print $4 $5}' | sed 's/[^0-9]*//g'`
NEWEST_CONTRIBUTION_NAME=`echo "$NEWEST_CONTRIBUTION" | awk '{print $6}'`
NEWEST_CONTRIBUTION_NAME=${NEWEST_CONTRIBUTION_NAME:2}
if [ $NEWEST_CONTRIBUTION_DATE -gt $DATE_OF_NEWEST_CONTRIBUTION ]; then
				
	echo "current newest contribution is $NEWEST_CONTRIBUTION_NAME with the time $NEWEST_CONTRIBUTION_DATE"

	#safe date of newest contribution so that files are not verified twice
	export DATE_OF_NEWEST_CONTRIBUTION=$NEWEST_CONTRIBUTION_DATE #used for easy testing with source command
	echo "export DATE_OF_NEWEST_CONTRIBUTION=$NEWEST_CONTRIBUTION_DATE " >> /root/project_env.sh #used for env export with cron job

	#If a new contribution is found, do verification and preparation for next round
	cd /app/
	echo "starting download; this could take a while..."
	$connect_to_sftp_server:$NEWEST_CONTRIBUTION_NAME /app/.

	echo "verifying the submission; this could take a while..."
	if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin verify_transform_constrained
	else
		cargo run --release --bin verify_transform
	fi

	echo "uploading to ftp server and documentation; this could take a while..."
	mv new_challenge challenge
	mv response "response-$TRUSTED_SETUP_TURN"
	
	#upload new challenge file for next candiate
	echo "put challenge" | $connect_to_sftp_server:challenges

	#document response from previous participant
	echo "put response-$TRUSTED_SETUP_TURN" | $connect_to_sftp_server:challenges

	#document new challenge file
	TIME=$(date +%s.%N)
	cp challenge "challenge-$TIME"
	echo "put challenge-$TIME" | $connect_to_sftp_server:challenges


	#safe new variables for next execution
	export TRUSTED_SETUP_TURN=$((TRUSTED_SETUP_TURN + 1)) #used for easy testing with source command
	echo "export TRUSTED_SETUP_TURN=$TRUSTED_SETUP_TURN " >> /root/project_env.sh #used for env export with cron job
	curl -d message="The submission of $NEWEST_CONTRIBUTION was successful. The new challenge for the $TRUSTED_SETUP_TURN -th contributor has been uploaded. If you want to be the next contributor, let us know in the chat. Your challenge would be ready here: sftp:trusted-setup.staging.gnosisdev.com:challenges" https://webhooks.gitter.im/e/$KEY_GITTER_TRUSTED_SETUP_ROOM
else
	echo "Newest contribution was created at $NEWEST_CONTRIBUTION_DATE and is not newer than $DATE_OF_NEWEST_CONTRIBUTION"
fi


