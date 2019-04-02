#!/bin/bash

##Setup:

cd /app/
# First a new ceremony setup is created via:
rm challenge
rm response
rm new_challenge
set -e 
if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin new_constrained
	else
		cargo run --release --bin new
fi

# Upload new challenge file to the challenges folder.
echo "put challenge" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

#document new challenge in same folder
#copying the first upload is not supported, see here: https://superuser.com/questions/1166354/copy-file-on-sftp-to-another-directory-without-roundtrip
TIME=$(date +%s.%N)
cp challenge "challenge-$TIME"
echo "put challenge-$TIME" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

#optional first computation
if [[ ! -z "${MAKEFIRSTCONTRIBUTION}" ]]; then
	
	if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin compute_constrained
	else
		cargo run --release --bin compute
	fi
	# Change to user worker and put into top level folder instead to josojo:
	echo "put response" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:validationworkertest
fi