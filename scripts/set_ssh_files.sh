#storing ssh key in folders for easier access
echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa_validation_worker
sed -i '1 i\-----BEGIN RSA PRIVATE KEY-----' /root/.ssh/id_rsa_validation_worker
echo "-----END RSA PRIVATE KEY-----" >> /root/.ssh/id_rsa_validation_worker

chmod 600 /root/.ssh/id_rsa_validation_worker

echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa_validation_worker.pub
sed -i '1 i\-ssh-rsa ' /root/.ssh/id_rsa_validation_worker.pub
echo "== root@3cdf27b687e2" >> /root/.ssh/id_rsa_validation_worker.pub