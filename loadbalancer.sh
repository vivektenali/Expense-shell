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
VALIDATE $? "Installing nginx"

rm -f /etc/nginx/nginx.conf
VALIDATE $? "Removing default nginx.conf"

cd /etc/nginx
VALIDATE $? "Changing directory to nginx"

cp $SCRIPT_DIR/loadbalancer.conf /etc/nginx/nginx.conf
VALIDATE $? "nginx.conf addded"

nginx -t
VALIDATE $? "Testing conf"

systemctl enable nginx
VALIDATE $? "Enable Nginx"

systemctl start nginx
VALIDATE $? "Start Nginx"

