#!/bin/bash

##Setup:

cd /app/
# First a new ceremony setup is created via:
rm challenge
rm response
rm new_challenge

if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin new_constrained
	else
		cargo run --release --bin new
fi

# Change to user worker and put into top level folder instead to josojo:
echo "put challenge" | sftp -i /root/.ssh/id_rsa_worker validationworker@trusted-setup.staging.gnosisdev.com:challenges

#optional first computation
if [[ ! -z "${MAKEFIRSTCONTRIBUTION}" ]]; then
	
	if [[ ! -z "${CONSTRAINED}" ]]; then
		cargo run --release --bin compute_constrained
	else
		cargo run --release --bin compute
	fi
	# Change to user worker and put into top level folder instead to josojo:
	echo "put response" | sftp -i /root/.ssh/id_rsa josojo@trusted-setup.staging.gnosisdev.com:josojo
if