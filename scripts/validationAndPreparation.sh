#!/bin/bash

get_all_contributor_files () {
  FILES=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker";cls;bye'`

  #no contribution in folder challenges expected
  echo "$FILES"
}

if [[ -z "${DATE_OF_NEWEST_CONTRIBUTION}" ]]; then
  DATE_OF_NEWEST_CONTRIBUTION=1
fi

if [[ -z "${TRUSTED_SETUP_TURN}" ]]; then
  TRUSTED_SETUP_TURN=1
fi

FILES="$(get_all_contributor_files)"
echo "files are $FILES"

unset NEWEST_CONTRIBUTION

#NEWEST_CONTRIBUTION="$(find_newer_contribution $DATE_OF_NEWEST_CONTRIBUTION)"
echo "search for files newer than ${DATE_OF_NEWEST_CONTRIBUTION}"
for f in $FILES
do
	if [[ !  $f == "challenges/" ]]; then
		echo "Processing $f"
		DATE=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $6}' | sed 's/[^0-9]*//g'`
		echo "DATE is $DATE"
		if [ $DATE -gt $DATE_OF_NEWEST_CONTRIBUTION ]; then
			echo "found newer contribution"
			DATE_OF_NEWEST_CONTRIBUTION=$DATE
			NEWEST_CONTRIBUTION=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $7}'`
			echo "newest contribution is $NEWEST_CONTRIBUTION"
		fi	
	fi
	
done

echo "current newest contribution is $NEWEST_CONTRIBUTION with the timestamp $DATE_OF_NEWEST_CONTRIBUTION"

#safe date of newest contribution so that files are not verified twice
export DATE_OF_NEWEST_CONTRIBUTION=$DATE_OF_NEWEST_CONTRIBUTION 

#If a new contribution is found, do verification and preparation for next step
if [[ !  -z "${NEWEST_CONTRIBUTION}" ]]; then
	cd /app/
	echo "starting download; this could take a while..."
	sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:$NEWEST_CONTRIBUTION /app/.

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
	echo "put challenge" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

	#document response from previous participant
	echo "put response-$TRUSTED_SETUP_TURN" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

	#document new challenge file
	TIME=$(date +%s.%N)
	cp challenge "challenge-$TIME"
	echo "put challenge-$TIME" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges
fi

#safe new variables for next execution
export TRUSTED_SETUP_TURN=$((TRUSTED_SETUP_TURN + 1))



