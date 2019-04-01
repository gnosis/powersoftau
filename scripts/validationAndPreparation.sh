#!/bin/bash

get_all_contributor_files () {
  FILES=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker";cls;bye'`

  #no contribution in folder challenges expected
  FILES=${FILES[@]/challenges/}
  echo "$FILES"
}


#find the newest file in the sftp server and store it in NEWESTFILE
find_newer_contribution(){
	DATEOFNEWESTCONTRIBUTION=$1
	echo 'search for files newer than $DATEOFNEWESTCONTRIBUTION'
	for f in $FILES
	do
		echo "Processing $f"
		DATE=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $6}' | sed 's/[^0-9]*//g'`
		echo "DATE is $DATE"
		if [ $DATE -gt $DATEOFNEWESTCONTRIBUTION ]; then
			echo "found newer contribution"
			DATEOFNEWESTCONTRIBUTION=$DATE
			NEWESTFILE=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $7}'`
			echo "newest contribution is $NEWESTFILE"
		fi	
	done
	echo "$NEWESTFILE"
}


if [[ -z "${DATEOFNEWESTCONTRIBUTION}" ]]; then
  DATEOFNEWESTCONTRIBUTION=1
fi

if [[ -z "${TRUSTEDSETUPTURN}" ]]; then
  TRUSTEDSETUPTURN=1
fi

FILES="$(get_all_contributor_files)"
echo "files are $FILES"

unset NEWESTFILE

#NEWESTFILE="$(find_newer_contribution $DATEOFNEWESTCONTRIBUTION)"
echo "search for files newer than ${DATEOFNEWESTCONTRIBUTION}"
for f in $FILES
do
	if [[  $f=="/" ]]; then
		continue 
	fi
	echo "Processing $f"
	DATE=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $6}' | sed 's/[^0-9]*//g'`
	echo "DATE is $DATE"
	if [ $DATE -gt $DATEOFNEWESTCONTRIBUTION ]; then
		echo "found newer contribution"
		DATEOFNEWESTCONTRIBUTION=$DATE
		NEWESTFILE=`lftp sftp://validationworker:@trusted-setup.staging.gnosisdev.com -e 'set sftp:connect-program "ssh -a -x -i /root/.ssh/id_rsa_worker"; cls -l --time-style=%FT%T '$f'/* --sort=date | head -1; bye' | awk '{print $7}'`
		echo "newest contribution is $NEWESTFILE"
	fi	
done

echo "current newest contribution is $NEWESTFILE with the timestamp $DATEOFNEWESTCONTRIBUTION"

#safe date of newest contribution so that files are not verified twice
export DATEOFNEWESTCONTRIBUTION=$DATEOFNEWESTCONTRIBUTION 

#If a new contribution is found, do verification and preparation for next step
if [[ !  -z "${NEWESTFILE}" ]]; then
	cd /app/
	echo "starting download; this could take a while..."
	sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:$NEWESTFILE /app/.

	echo "verifying the submission; this could take a while..."
	if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin verify_transform_constrained
	else
		cargo run --release --bin verify_transform
	fi

	echo "uploading to ftp server and documentation; this could take a while..."
	mv new_challenge challenge
	mv response "response-$TRUSTEDSETUPTURN"
	
	#upload new challenge file for next candiate
	echo "put challenge" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

	#document response from previous participant
	echo "put response-$TRUSTEDSETUPTURN" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

	#document new challenge file
	TIME=$(date +%s.%N)
	cp challenge "challenge-$TIME"
	echo "put challenge-$TIME" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges
fi

#safe new variables for next execution
export TRUSTEDSETUPTURN=$TRUSTEDSETUPTURN+1

