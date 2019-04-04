. /app/variables.sh
chmod 600 /root/.ssh/id_rsa_worker
. /app/variables.sh
connect_to_sftp_server="sftp -i /root/.ssh/id_rsa_worker -o StrictHostKeyChecking=no $SSH_USER@$SFTP_ADDRESS"
