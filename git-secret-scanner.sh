#!/bin/bash

set -e
set -o pipefail

CLI="cx"
REPO_URL="$1"
BRANCH_NAME="$2"

if [ -z "$REPO_URL" ]; then
  echo "❌ Error: REPO_URL not provided"
  exit 1
fi

echo "✅ Repo URL: $REPO_URL"
echo "✅ Branch Name: $BRANCH_NAME"

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
mkdir -p report_output

# Configure AST CLI
cx configure set --prop-name 'cx_base_uri' --prop-value 'https://deu.ast.checkmarx.net/'
cx configure set --prop-name 'cx_base_auth_uri' --prop-value 'https://deu.iam.checkmarx.net/'
cx configure set --prop-name 'cx_tenant' --prop-value 'cx-cs-na-pspoc'
cx configure set --prop-name 'cx_apikey' --prop-value "eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NmM5YThiYy0xYTliLTQyNjItOGRhNi1hM2M0MGE4YWJhMzYifQ..."

# Run scan (outputs directly to ./report_output)
cx scan create --project-name "ado-project" --branch "$BRANCH_NAME" \
  -s "$REPO_URL" --scan-types "sast, sca" \
  --report-format json --report-format summaryHTML \
  --output-name "ado-report" --output-path "./report_output" \
  --report-pdf-email hiren.soni46@yahoo.com --report-pdf-options sast \
  --ignore-policy --debug

# Send the email using msmtp + mutt
echo "Sending email with report..."
sudo apt-get update && sudo apt-get install -y msmtp msmtp-mta mutt

# Setup SMTP config
cat <<EOF > ~/.msmtprc
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from hirendhakan8080@gmail.com
user hirendhakan8080@gmail.com
password ndmrjelrrioqoiuk

account default : gmail
EOF

chmod 600 ~/.msmtprc

# Email the HTML summary
if [[ -f "report_output/ado-report.summaryHTML" ]]; then
  echo "This email includes an attachment of project summary." | mutt -s "Project Scan Summary" \
    -a "report_output/ado-report.summaryHTML" -- hiren.soni46@yahoo.com
  echo "✅ Report sent successfully."
else
  echo "⚠️ Report file not found, skipping email."
fi
