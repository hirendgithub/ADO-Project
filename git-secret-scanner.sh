#!/bin/bash

set -e
set -o pipefail

# CLI binary assumed to be globally available as 'cx'
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

# Configure AST CLI
cx configure set --prop-name 'cx_base_uri' --prop-value 'https://deu.ast.checkmarx.net/'
cx configure set --prop-name 'cx_base_auth_uri' --prop-value 'https://deu.iam.checkmarx.net/'
cx configure set --prop-name 'cx_tenant' --prop-value 'cx-cs-na-pspoc'
cx configure set --prop-name 'cx_apikey' --prop-value "eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NmM5YThiYy0xYTliLTQyNjItOGRhNi1hM2M0MGE4YWJhMzYifQ.eyJpYXQiOjE3NDg5NTM2MjksImp0aSI6ImE0ZmJmZTZlLTc1NWUtNDRkMC04MWUyLTM1MDMwZDhjYjY1OSIsImlzcyI6Imh0dHBzOi8vZGV1LmlhbS5jaGVja21hcngubmV0L2F1dGgvcmVhbG1zL2N4LWNzLW5hLXBzcG9jIiwiYXVkIjoiaHR0cHM6Ly9kZXUuaWFtLmNoZWNrbWFyeC5uZXQvYXV0aC9yZWFsbXMvY3gtY3MtbmEtcHNwb2MiLCJzdWIiOiJlYTlmMDc0YS1jOGMxLTQ3ODgtYjg0YS01ZDQ1MjZmMWVmYTMiLCJ0eXAiOiJPZmZsaW5lIiwiYXpwIjoiYXN0LWFwcCIsInNpZCI6ImYwZDBiYzUzLTU2OTgtNDg0Mi1iN2FiLTc5YzY5NjU2ZTBlNCIsInNjb3BlIjoicm9sZXMgcHJvZmlsZSBhc3QtYXBpIGlhbS1hcGkgZW1haWwgb2ZmbGluZV9hY2Nlc3MifQ.MiALYYrbUCxuBRz_VxlyOepeRSwn_5ZZtCVsXwP70i6XBGjq4ohXKxq_zBLw5ClWVpSHI6LlDBholNP_EjkdVg"

# === Move report to root-level directory ===
cd ../..
mkdir -p report_output
mv scanned_project/$(basename "$REPO_URL" .git)/ado-report* report_output/

# === Install msmtp and send email with attachment ===
echo "Sending email with report..."
sudo apt-get update && sudo apt-get install -y msmtp msmtp-mta

# Run scan
cx scan create --project-name "ado-project" --branch "$BRANCH_NAME" \
  -s "$REPO_URL" --scan-types "sast, sca" \
  --report-format json --report-format summaryHTML \
  --output-name "ado-report" --output-path "." \
  --report-pdf-email hiren.soni46@yahoo.com --report-pdf-options sast \
  --ignore-policy --debug

# Create msmtp config
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

# Send the email using msmtp + mutt
sudo apt-get install -y mutt
echo "This email includes an attachment of project summary." | mutt -s "Project Scan Summary" \
  -a "report_output/ado-report.summaryHTML" \
  -- hiren.soni46@yahoo.com

echo "✅ Report sent successfully."
