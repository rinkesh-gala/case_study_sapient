#! /bin/bash
# Copyright 2015 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START startup]
set -v

# Talk to the metadata server to get the project id
PROJECTID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")

# Install logging monitor. The monitor will automatically pickup logs sent to
# syslog.
# [START logging]
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
sudo bash add-logging-agent-repo.sh --also-install
# [END logging]

#Install CloudSQL proxy
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy


# Install dependencies from apt
sudo apt update
sudo apt install git build-essential supervisor python3  python3-pip python3-virtualenv mysql-client-core-8.0 net-tools libssl-dev -y

# Create a pythonapp user. The application will run as this user.
useradd -m -d /home/pythonapp pythonapp

# pip from apt is out of date, so make it update itself and install virtualenv.
#pip install --upgrade pip virtualenv
pip3 install virtualenv

# Get the source code from the Google Cloud Repository
# git requires $HOME and it's not set during the startup script.
export HOME=/root
git config --global credential.helper gcloud.sh
${REPONAME}
sduo git clone https://github.com/GoogleCloudPlatform/getting-started-python.git -b steps /opt/app
#git clone https://source.developers.google.com/p/flowing-coil-348605/r/python-code /opt/app
#git clone https://source.cloud.google.com/flowing-coil-348605/github_rinkeshgala1_terraform/+/main:

#cp /opt/app/7-gce/config.py .
sudo sed -i 's/datastore/cloud-sql/g' /opt/app/7-gce/config.py
sudo sed -i 's/your-project-id/flowing-coil-348605/g' /opt/app/7-gce/config.py
sudo sed -i 's/bookshelf/mysql-db/g' /opt/app/7-gce/config.py
sudo sed -i 's/root/mysqladmin/g' /opt/app/7-gce/config.py
sudo sed -i 's/your-cloudsql-password/Qwerty1!/g' /opt/app/7-gce/config.py
sudo sed -i 's/your-bucket-name/bookshelf-gcs-1a/g' /opt/app/7-gce/config.py
sudo sed -i 's/your-cloudsql-connection-name/flowing-coil-348605:us-central1:bookshelf-mysql-instance-1a/g' /opt/app/7-gce/config.py
bookshelf-gcs-1a

cat config.py | grep cloud-sql
cat config.py | grep flowing-coil-348605


# Install app dependencies
sudo virtualenv -p python3 /opt/app/7-gce/env
source /opt/app/7-gce/env/bin/activate
sudo /opt/app/7-gce/env/bin/pip install -r /opt/app/7-gce/requirements.txt

# Make sure the pythonapp user owns the application code
sudo chown -R pythonapp:pythonapp /opt/app

# Configure supervisor to start gunicorn inside of our virtualenv and run the
# application.
sudo cat >/etc/supervisor/conf.d/python-app.conf << EOF
[program:pythonapp]
directory=/opt/app/7-gce
command=/opt/app/7-gce/env/bin/honcho start -f ./procfile worker bookshelf
autostart=true
autorestart=true
user=pythonapp
# Environment variables ensure that the application runs inside of the
# configured virtualenv.
environment=VIRTUAL_ENV="/opt/app/7-gce/env",PATH="/opt/app/7-gce/env/bin",\
    HOME="/home/pythonapp",USER="pythonapp"
stdout_logfile=syslog
stderr_logfile=syslog
EOF

sudo supervisorctl reread
sudo supervisorctl update

# Application should now be running under supervisor
# [END startup]
