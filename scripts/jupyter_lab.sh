#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Update and install required packages
apt update && apt upgrade -y
apt install python3 python3-pip python3-venv expect -y

# Create necessary directories
mkdir -p /jupyterlab/workspace
echo "Project directory created in /jupyterlab."

cd /jupyterlab

# Create a virtual environment without activation in the script
python3 -m venv venv
echo "Virtual environment created in /jupyterlab."

# Upgrade pip and install Jupyter directly using the virtual environment's pip
/jupyterlab/venv/bin/pip3 install --upgrade pip
/jupyterlab/venv/bin/pip3 install jupyter

# Generate Jupyter password
jupyter_password=${jupyter_password}

expect <<EOF
spawn /jupyterlab/venv/bin/jupyter lab password
expect "Enter password:"
send "$jupyter_password\r"
expect "Verify password:"
send "$jupyter_password\r"
expect eof
EOF

# Create a systemd service for Jupyter Lab
cat <<EOF | sudo tee /etc/systemd/system/jupyterlab.service
[Unit]
Description=Jupyter Lab Server
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=/jupyterlab/workspace
ExecStart=/jupyterlab/venv/bin/jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable the systemd service to run at startup
sudo systemctl daemon-reload
sudo systemctl enable jupyterlab.service
sudo systemctl start jupyterlab.service

echo "Jupyter Lab has been configured and started in /jupyterlab."
