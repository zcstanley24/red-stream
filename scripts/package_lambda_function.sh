#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <producer|transformer>"
  exit 1
fi

LAMBDA_NAME="$1"

echo "Deleting old package folder and replacing with new one"
cd ./build
rm -rf ./lambda_${LAMBDA_NAME}_package
rm -f ./lambda_${LAMBDA_NAME}_payload.zip
mkdir ./lambda_${LAMBDA_NAME}_package

echo "Installing dependencies"
if [ "$LAMBDA_NAME" = "producer" ]; then
  python3 -m pip install praw -t ./lambda_${LAMBDA_NAME}_package --no-user
fi
python3 -m pip install python-dotenv -t ./lambda_${LAMBDA_NAME}_package --no-user

cp ../src/lambda_${LAMBDA_NAME}/lambda_${LAMBDA_NAME}.py ./lambda_${LAMBDA_NAME}_package/
cd ./lambda_${LAMBDA_NAME}_package
echo "Packaged lambda ${LAMBDA_NAME} into lambda_${LAMBDA_NAME}_payload.zip"
read -p "Press ENTER to exit..."