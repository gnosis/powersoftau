#!/bin/bash
set -e 
## checks that the processes running is not bigger than 5. If so, then the server is still validating
AMOUNT_OF_PROCESSES_RUNNING=$(ps -ef | wc -l)
echo "Nr. of processes running: $AMOUNT_OF_PROCESSES_RUNNING"
NR_OF_PROCESSES_IN_BACKGROUND=9
if [ $AMOUNT_OF_PROCESSES_RUNNING -le $NR_OF_PROCESSES_IN_BACKGROUND ]; then
        #If the validator is not working, a new one is started
        . /app/scripts/validationAndPreparation.sh 
        exit 0
else
		exit 0
fi