#!/bin/bash

LOGS_FOLDER=/var/logs/expenseLogs
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf install nginx -y
VALIDATE $? "Validating Nginx"

systemctl enable nginx
VALIDATE $? "Enabling Nginx"

systemctl start nginx
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing the default Nginx content"

curl -o /tmp/frontend.tar.gz https://raw.githubusercontent.com/vivektenali/Expense-shell/refs/heads/main/artifacts/expense-frontend-v3.tar.gz
VALIDATE $? "Downloading content"

cd /usr/share/nginx/html
tar -xzf /tmp/frontend.tar.gz --strip-components=1
VALIDATE $? "Extracting the Zip in the /usr/share/nginx/html/"

cp $SCRIPT_DIR/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Configuring Nginx Reverse Proxy"

nginx -t
VALIDATE $? "Testing the config"

systemctl restart nginx
VALIDATE $? "Restart Nginx"