#!/bin/bash
set -e

echo "Deleting old package folder and replacing with new one"
cd ./build
rm -rf ./lambda_producer_package
rm -f ./lambda_producer_payload.zip
mkdir ./lambda_producer_package

echo "Installing dependencies"
python3 -m pip install praw -t ./lambda_producer_package --no-user
python3 -m pip install python-dotenv -t ./lambda_producer_package --no-user

cp ../src/lambda_producer/lambda_producer.py ./lambda_producer_package/
cd ./lambda_producer_package
# tar -a -c -f ../lambda_producer_payload.zip .
echo "Packaged lambda producer into lambda_producer_payload.zip"
read -p "Press ENTER to exit..."