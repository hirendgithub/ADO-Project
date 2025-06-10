#!/bin/bash

set -e
set -o pipefail

CLI="cx"
REPO_URL="$1"
BRANCH_NAME="$2"

if [ -z "$REPO_URL" ]; then
  echo " Error: REPO_URL not provided"
  exit 1
fi

echo " Repo URL: $REPO_URL"
echo " Branch Name: $BRANCH_NAME"

timestamp=$(date +"%d_%m_%Y_%H_%M_%S")
Report_name="demo_project_$timestamp"

# Clone repo
mkdir -p scanned_project
cd scanned_project
git clone "$REPO_URL"
cd "$(basename "$REPO_URL" .git)"

if [ -n "$BRANCH_NAME" ]; then
  git checkout "$BRANCH_NAME"
fi

# Go back to root for consistent output directory path
cd ../..

# Create output dir
sudo mkdir -m 755 report_output
sudo chmod -R 777 report_output

# Configure AST CLI
cx configure set --prop-name 'cx_base_uri' --prop-value 'https://deu.ast.checkmarx.net/'
cx configure set --prop-name 'cx_base_auth_uri' --prop-value 'https://deu.iam.checkmarx.net/'
cx configure set --prop-name 'cx_tenant' --prop-value 'cx-cs-na-pspoc'
cx configure set --prop-name 'cx_apikey' --prop-value 'eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NmM5YThiYy0xYTliLTQyNjItOGRhNi1hM2M0MGE4YWJhMzYifQ.eyJpYXQiOjE3NDg5NTM2MjksImp0aSI6ImE0ZmJmZTZlLTc1NWUtNDRkMC04MWUyLTM1MDMwZDhjYjY1OSIsImlzcyI6Imh0dHBzOi8vZGV1LmlhbS5jaGVja21hcngubmV0L2F1dGgvcmVhbG1zL2N4LWNzLW5hLXBzcG9jIiwiYXVkIjoiaHR0cHM6Ly9kZXUuaWFtLmNoZWNrbWFyeC5uZXQvYXV0aC9yZWFsbXMvY3gtY3MtbmEtcHNwb2MiLCJzdWIiOiJlYTlmMDc0YS1jOGMxLTQ3ODgtYjg0YS01ZDQ1MjZmMWVmYTMiLCJ0eXAiOiJPZmZsaW5lIiwiYXpwIjoiYXN0LWFwcCIsInNpZCI6ImYwZDBiYzUzLTU2OTgtNDg0Mi1iN2FiLTc5YzY5NjU2ZTBlNCIsInNjb3BlIjoicm9sZXMgcHJvZmlsZSBhc3QtYXBpIGlhbS1hcGkgZW1haWwgb2ZmbGluZV9hY2Nlc3MifQ.MiALYYrbUCxuBRz_VxlyOepeRSwn_5ZZtCVsXwP70i6XBGjq4ohXKxq_zBLw5ClWVpSHI6LlDBholNP_EjkdVg'

# Run scan (outputs directly to ./report_output)
echo " Running Checkmarx scan..."
if ! cx scan create --project-name "ado-project" --branch "$BRANCH_NAME" \
  -s "$REPO_URL" --scan-types "sast, sca" \
  --report-format json --report-format summaryHTML \
  --output-name "$Report_name" --output-path "report_output" \
  --ignore-policy --debug; then
  echo " cx scan failed"
  exit 1
fi

# Debug output to verify reports were created
echo " Listing contents of report_output:"
ls -lh report_output || echo " report_output directory not found"

echo " Searching for $Report_name.* files..."
find report_output -type f -name "$Report_name.*"

# Install msmtp and mutt for email
echo " Installing msmtp and mutt..."
sudo apt-get update && sudo apt-get install -y msmtp msmtp-mta mutt

# Setup SMTP config
echo " Configuring email settings..."
cat <<EOF > ~/.msmtprc
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account $ACCOUNT
host $HOST
port $PORT
from $SENDER_EMAIL
user $SENDER_EMAIL_USERNAME
password $SENDER_EMAIL_PASSWORD

account default : $ACCOUNT_DEFAULT
EOF

chmod 600 ~/.msmtprc

# === Smart Report Detection and Email ===
echo " Looking for any summaryHTML report file in report_output/"
REPORT_FILE=$(find report_output -type f -name "*.html" | head -n 1)


if [[ -f "$REPORT_FILE" ]]; then
 echo " Sending report via email: $REPORT_FILE"
  echo "This email includes an attachment of project summary." | mutt -s "Project Scan Summary" \
   -a "$REPORT_FILE" -- $RECIPIENT_EMAIL
  echo " Report sent successfully."
else
  echo
  echo " Report file not found at expected location: report_output/html"
  echo "Skipping email."
fi
