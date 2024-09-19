#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Update and install required packages
apt update && apt upgrade -y
apt install python3 python3-pip python3-venv expect -y

# Create the jupyter user
useradd -m -s /bin/bash jupyter
echo "User 'jupyter' created."

# Set a password for the jupyter user (optional, can be skipped if not needed)
# echo "jupyter:<your-password>" | sudo chpasswd

# Create necessary directories with the correct ownership
mkdir -p /jupyterlab/workspace
chown -R jupyter:jupyter /jupyterlab
echo "Project directory created in /jupyterlab with 'jupyter' user ownership."

cd /jupyterlab

# Create a virtual environment under the 'jupyter' user
sudo -u jupyter python3 -m venv /jupyterlab/venv
echo "Virtual environment created in /jupyterlab."

# Upgrade pip and install Jupyter directly using the virtual environment's pip
sudo -u jupyter /jupyterlab/venv/bin/pip3 install --upgrade pip
sudo -u jupyter /jupyterlab/venv/bin/pip3 install jupyter

# Generate Jupyter password
jupyter_password=${jupyter_password}

expect <<EOF
spawn sudo -u jupyter /jupyterlab/venv/bin/jupyter lab password
expect "Enter password:"
send "$jupyter_password\r"
expect "Verify password:"
send "$jupyter_password\r"
expect eof
EOF

# Create a systemd service for Jupyter Lab using the 'jupyter' user
cat <<EOF | sudo tee /etc/systemd/system/jupyterlab.service
[Unit]
Description=Jupyter Lab Server
After=network.target

[Service]
Type=simple
User=jupyter
WorkingDirectory=/jupyterlab/workspace
ExecStart=/bin/bash -c "source /jupyterlab/venv/bin/activate && exec /jupyterlab/venv/bin/jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable the systemd service to run at startup
sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl start jupyterlab.service

echo "Jupyter Lab has been configured and started with 'jupyter' user in /jupyterlab."
