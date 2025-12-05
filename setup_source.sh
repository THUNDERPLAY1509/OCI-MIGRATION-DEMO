#!/bin/bash
# RUN THIS ON YOUR "SOURCE" VM (e.g., Local VirtualBox or AWS EC2)
# It simulates the On-Premises environment.

echo "--- 1. Updating System ---"
sudo apt-get update -y

echo "--- 2. Installing Python & MySQL Server ---"
sudo apt-get install -y python3 python3-pip mysql-server

echo "--- 3. Installing Python Dependencies ---"
pip3 install flask mysql-connector-python

echo "--- 4. Configuring MySQL User & Database ---"
# We create a specific user for the app to simulate a real environment
sudo mysql -e "CREATE USER IF NOT EXISTS 'app_user'@'localhost' IDENTIFIED BY 'Welcome123!';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "--- 5. Loading Schema & Data ---"
# Assumes schema.sql is in the same folder
if [ -f "schema.sql" ]; then
    sudo mysql -u root < schema.sql
    echo "Schema loaded successfully."
else
    echo "ERROR: schema.sql not found!"
fi

echo "--- 6. Setup Complete! ---"
echo "You can now run the app using: python3 app.py"