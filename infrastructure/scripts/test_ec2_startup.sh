#!/bin/bash

# Fetch public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Set hostname
HOSTNAME="test-ec2-$PUBLIC_IP"
sudo hostnamectl set-hostname $HOSTNAME
sudo hostnamectl 

# Update /etc/hosts
echo "127.0.0.1   $HOSTNAME" | sudo tee -a /etc/hosts

# Ensure the hostname is applied immediately for the current session
export PS1="[\u@$HOSTNAME \W]\$ "

#!/bin/bash
mkdir -p /home/ec2-user/.ssh
echo '${public_key}' >> /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

sudo rm /usr/lib/motd.d/10-uname
sudo rm /usr/lib/motd.d/20-*  # Remove any other MOTD scripts

sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Load AWS command database
cat <<'EOF' > /home/ec2-user/aws_commands.json
${aws_commands}
EOF

# Load python script
cat <<'EOF' > /home/ec2-user/aws_vpce_policy_tester.py
${tester_script}
EOF


sed -i "s|source_ssh_net|${source_ssh_net}|g" /home/ec2-user/aws_vpce_policy_tester.py
sed -i "s|OPTION_DESCRIPTION|${option_description}|g" /home/ec2-user/aws_vpce_policy_tester.py
sed -i "s|VAR_ACCOUNT_ID|${account_id}|g" /home/ec2-user/aws_vpce_policy_tester.py
sed -i "s|VAR_ACCOUNT_ID|${account_id}|g" /home/ec2-user/aws_commands.json

                                
ASCII_ART='  ______   __       __   ______  
 /      \ |  \  _  |  \ /      \ 
|  $$$$$$\| $$ / \ | $$|  $$$$$$\
| $$__| $$| $$/  $\| $$| $$___\$$
| $$    $$| $$  $$$\ $$ \$$    \ 
| $$$$$$$$| $$ $$\$$\$$ _\$$$$$$\
| $$  | $$| $$$$  \$$$$|  \__| $$
| $$  | $$| $$$    \$$$ \$$    $$
 \$$   \$$ \$$      \$$  \$$$$$$ '


# Create the key.json file for the DynamoDB get-item command
echo '{
  "id": {
    "S": "bogus"
  }
}' > /home/ec2-user/key.json

# Create the item.json file for the DynamoDB put-item command
echo '{
  "id": {
    "S": "bogus"
  }
}' > /home/ec2-user/item.json

# Create the log-events.json file for the CloudWatch put-log-events command
echo '[
  {
    "timestamp": 1234567890,
    "message": "bogus-log-message"
  }
]' > /home/ec2-user/log-events.json

# Create the targets.json file for the ssm send-command
echo '[
  {
    "Key": "InstanceIds",
    "Values": ["bogus-instance-id"]
  }
]' > /home/ec2-user/targets.json

# Create the new banner content directly into the file
{
  echo ""
  echo "$ASCII_ART"    
  echo ""
  echo "Welcome to the VPC Endpoint Tester VM."
  echo "The Terraform Scripts built this to test Option${option} which configures ${option_description} as a condition in vpc endpoint policy."
  echo "Use the following command to show usage:"
  echo "python3 aws_vpce_policy_tester.py"
  echo ""
} | sudo tee /usr/lib/motd.d/30-banner

sudo systemctl daemon-reload

# Install required packages
sudo yum update -y
sudo yum install -y python3 python3-pip

# Install SSM Agent
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install required python packages
pip3 install argparse

