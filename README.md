# Powers of Tau

## Original story

This is a [multi-party computation](https://en.wikipedia.org/wiki/Secure_multi-party_computation) (MPC) ceremony which constructs partial zk-SNARK parameters for _all_ circuits up to a depth of 2<sup>21</sup>. It works by taking a step that is performed by all zk-SNARK MPCs and performing it in just one single ceremony. This makes individual zk-SNARK MPCs much cheaper and allows them to scale to practically unbounded numbers of participants.

This protocol is described in a [forthcoming paper](https://eprint.iacr.org/2017/1050). It produces parameters for an adaptation of [Jens Groth's 2016 pairing-based proving system](https://eprint.iacr.org/2016/260) using the [BLS12-381](https://github.com/ebfull/pairing/tree/master/src/bls12_381) elliptic curve construction. The security proof relies on a randomness beacon being applied at the end of the ceremony.

## Contributions

Extended to support Ethereum's BN256 curve and made it easier to change size of the ceremony. In addition proof generation process can be done in memory constrained environments now. Benchmark is around `1.3 Gb` of memory and `3 hours` for a `2^26` power of tau on BN256 curve on my personal laptop

## Instructions

Every participant needs to create a ssh key for accessing the sftp server. For help see [here](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html). Please provide the public key in the [gitter group](https://gitter.im/Trusted_setup_for_SNAPPS/community). In this group, the trusted setup participant's turns will also be organized. Once it is your turn, you are supposed to do the following steps:

#Procedure:

1. Download latest challenge file from sftp-server with your ssl key.
	You can use an UI program as Filezilla (host is sftp://trusted-setup.staging.gnosisdev.com) or the following shell command:
	```bash
	sftp -i ~/.ssh/id_rsa  your_usr_name@trusted-setup.staging.gnosisdev.com:challenges/challenge
	```
2. Generate the exectuable binary:
	```bash
	git clone git@github.com:matterinc/powersoftau.git
	cd powersoftau
	cargo build --release --bin compute_constrained
	```
	or download it from here:
	`sftp://trusted-setup.staging.gnosisdev.com:testalex/compute_constrained`
3. Copy the downloaded challenge file and the newly generated executable from `powersoftau/target/release/compute_constrained` to your dedicated computer for the trusted setup into a folder: `Execution`.	
4. (Optional) Perform some of the recommended steps from the next section.
5. Make sure your dedicated computer for the ceremony will not fall asleep, even if the following step takes several hours.
6. On the dedicated computer, do the acutal computation from within the `Execution` folder by running:
	```bash
	./compute_constrained
	```
7. Broadcast your contribution hash via twitter or your preferred social media account. 
8. Upload the 'response' file to sftp-server into the your own folder (your_ssl_user_name) via Filezilla or:
	```bash
	echo "put response" | sftp -i ~/.ssh/id_rsa  your_user_name@trusted-setup.staging.gnosisdev.com::your_ssl_user_name
	```  

## Recommendations from original ceremony

Participants of the ceremony sample some randomness, perform a computation, and then destroy the randomness. **Only one participant needs to do this successfully to ensure the final parameters are secure.** In order to see that this randomness is truly destroyed, participants may take various kinds of precautions:

* putting the machine in a Faraday cage
* destroying the machine afterwards
* running the software on secure hardware
* not connecting the hardware to any networks
* using multiple machines and randomly picking the result of one of them to use
* using different code than what we have provided
* using a secure operating system
* using an operating system that nobody would expect you to use (Rust can compile to Mac OS X and Windows)
* using an unusual Rust toolchain or [alternate rust compiler](https://github.com/thepowersgang/mrustc)
* lots of other ideas we can't think of

It is totally up to the participants. In general, participants should beware of side-channel attacks and assume that remnants of the randomness will be in RAM after the computation has finished.

## Running docker image for automatic validation 

For starting the docker, just run:
```bash
 docker build --tag=validation_worker .
 docker run -it -v ~/.ssh/:/root/.ssh -v ~/gnosis/powersoftau:/app/ -v ~/gnosis/powersoftau/tmp:/tmp --env-file ./variables.sh validation_worker bash
```
This requires a prepared env file looking like this:
```
THRESHOLD_DATE_FOR_FILE_ACCEPTANCE=20190509091113
TRUSTED_SETUP_TURN=10
SFTP_ADDRESS=trusted-setup.staging.gnosisdev.com
MAKE_FIRST_CONTRIBUTION=yes
CONSTRAINED=true
SSH_USER=validationworker
SSH_FILE=id_rsa_worker
CHALLENGE_WORKDIR=/tmp
DATABASE_FILE_PATH=/app/variables.sh
RUST_BACKTRACE=1
GITTER_ACCESS_TOKEN=<token>
GITTER_ROOM=5ca22b42d73408ce4fbc758e
```

Once logged into the docker, the following scripts are helpful:
```bash
#setting up env variables for cron job
printenv | sed 's/^\(.*\)$/export \1/g' > /root/project_env.sh
#changing size of trusted setup(for testing only)
sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 8;/g' /app/src/bn256/mod.rs
sed -i 's/const REQUIRED_POWER: usize = [0-9][0-9];*/const REQUIRED_POWER: usize = 8;/g' /app/src/small_bn256/mod.rs
#Make the first inital generation and upload it to the server
. scripts/initial_setup.sh 
#starting cron
cron
#see logs of cron job
nano /var/log/cron.log
```


## License

Licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.
