#!/bin/bash

#######################################################################
assert ()                 #  If condition false,
{                         #+ exit from script
                          #+ with appropriate error message.
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99


  if [ -z "$2" ]          #  Not enough parameters passed
  then                    #+ to assert() function.
    return $E_PARAM_ERR   #  No damage done.
  fi

  lineno=$2

  if [ ! $1 ] 
  then
    echo "Assertion failed:  \"$1\""
    echo "File \"$0\", line $lineno"    # Give name of file and line number.
    exit $E_ASSERT_FAILED
  # else
  #   return
  #   and continue executing the script.
  fi  
} # Insert a similar assert() function into a script you need to debug.    
#######################################################################

connect_to_sftp_server="sftp -i /root/.ssh/$SSH_FILE $SSH_USER@trusted-setup.staging.gnosisdev.com"

export MAKEFIRSTCONTRIBUTION=yes

sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 8;/g' /app/src/bn256/mod.rs
sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 8;/g' /app/src/small_bn256/mod.rs

printf 'entropyForSolutionGeneration' | source /app/scripts/initial_setup.sh
touch response 
echo "safsdf" >> response
less response
echo "put response" | $connect_to_sftp_server:test_user

source /app/scripts/validationAndPreparation.sh

condition="$DATE_OF_NEWEST_CONTRIBUTION -ge 1"
LINENO="Contribution date not adjusted"
assert "$condition" $LINENO

condition="$TRUSTED_SETUP_TURN -le 1"
LINENO="Contribution turn not was adjusted, although upload was invalid"
assert "$condition" $LINENO

#reseting values
sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 26;/g' /app/src/bn256/mod.rs
sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 26;/g' /app/src/small_bn256/mod.rs