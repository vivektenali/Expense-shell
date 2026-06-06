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

dnf module disable nodejs -y
VALIDATE $? "Disabling default nodejs version"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y  &>> $LOGS_FILE
VALIDATE $? "Installing nodejs"

node -v  &>> $LOGS_FILE
VALIDATE $? "checking node version"

mkdir /app
VALIDATE $? "App directory"

useradd --system --home /app --shell /sbin/nologin --comment "expense system user" expense
VALIDATE $? "Expense System user"

curl -o /tmp/backend.tar.gz https://raw.githubusercontent.com/vivektenali/Expense-shell/refs/heads/main/artifacts/expense-backend-v3.tar.gz  &>> $LOGS_FILE
VALIDATE $? "Zip file Downloading"

cd /app
VALIDATE $? "Moving to App directory"

tar -xzf /tmp/backend.tar.gz --strip-components=1
VALIDATE $? "Extracting the zip"

npm install  &>> $LOGS_FILE  &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/backend.service /etc/systemd/system/backend.service 
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h database.vivektenali.online -u root -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Load Data"

systemctl daemon-reload
VALIDATE $? "daemon-reload"
systemctl enable backend
VALIDATE $? "enabling backend"
systemctl start backend
VALIDATE $? "starting backend"