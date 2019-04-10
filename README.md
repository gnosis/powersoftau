# Powers of Tau

## Original story

This is a [multi-party computation](https://en.wikipedia.org/wiki/Secure_multi-party_computation) (MPC) ceremony which constructs partial zk-SNARK parameters for _all_ circuits up to a depth of 2<sup>21</sup>. It works by taking a step that is performed by all zk-SNARK MPCs and performing it in just one single ceremony. This makes individual zk-SNARK MPCs much cheaper and allows them to scale to practically unbounded numbers of participants.

This protocol is described in a [forthcoming paper](https://eprint.iacr.org/2017/1050). It produces parameters for an adaptation of [Jens Groth's 2016 pairing-based proving system](https://eprint.iacr.org/2016/260) using the [BLS12-381](https://github.com/ebfull/pairing/tree/master/src/bls12_381) elliptic curve construction. The security proof relies on a randomness beacon being applied at the end of the ceremony.

## Contributions

Extended to support Ethereum's BN256 curve and made it easier to change size of the ceremony. In addition proof generation process can be done in memory constrained environments now. Benchmark is around `1.3 Gb` of memory and `3 hours` for a `2^26` power of tau on BN256 curve on my personal laptop

## Instructions

Every participant needs to create a ssh key. For help see [here](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html). Please provide the public key in the [gitter group](https://gitter.im/Trusted_setup_for_SNAPPS/community). Then, we will propose a slot for the participation for you. Once we agreed on a slot, you are supposed to do the following steps:

#Procedure:

1. You download latest challenge file from ftp-server with your ssl key.
	You can use an UI program as Filezilla(host is trusted-setup.gnosis.pm) or the following shell command:
		```bash
		sftp -i ~/.ssh/id_rsa  your_user_name@trusted-setup.gnosis.pm:challenges//challenge ~/challenge
		```
2. Copy the downloaded challenge file to your dedicated computer for running the ceremony.
3. Download the repository
	git clone git@github.com:matterinc/powersoftau.git
	and copy it to your dedicated computer.
4. Perform some of the recommended steps for ceremony from the next section.	
5. Then do the acutal computation:
	 cargo run --release --bin compute
6. Broadcast your contribution hash via twitter or your preferred social media account. 
7. Upload the 'response' file to ftp-server via Filezilla or:
```bash
echo "put response" | sftp -i ~/.ssh/id_rsa  your_user_name@trusted-setup.gnosis.pm:your_user_name
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
 docker run -it -v ~/.ssh/:/root/.ssh -e CONSTRAINED=true 
 -e SSH_PRIVATE_KEY=<private key> -e SSH_PUBLIC_KEY=<public key>
 -e SSH_USER=validationworker -e SFTP_ADDRESS=trusted-setup.staging.gnosisdev.com -e THRESHOLD_DATE_FOR_FILE_ACCEPTANCE=1 -e TRUSTED_SETUP_TURN=1 -e MAKE_FIRST_CONTRIBUTION=yes -e KEY_GITTER_TRUSTED_SETUP_ROOM=2ae0b8adf55e84b3bd41 validation_worker bash
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
