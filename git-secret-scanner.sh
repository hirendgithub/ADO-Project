#!/bin/bash
 
set -e  # exit on first error
set -o pipefail  # fail if any piped command fails
 
# Get CLI path
#CLI="/home/runner/ast-cli_2.3.21_linux_x64"  # Adjust if path differs
CLI="./ast-cli_2.3.21_linux_x64"

# Read variables passed from GitHub Actions
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
cd "$CLI"
 
cx configure set --prop-name 'cx_base_uri' --prop-value 'https://deu.ast.checkmarx.net/'
cx configure set --prop-name 'cx_base_auth_uri' --prop-value 'https://deu.iam.checkmarx.net/'
cx configure set --prop-name 'cx_tenant' --prop-value 'cx-cs-na-pspoc'
cx configure set --prop-name 'cx_apikey' --prop-value "$CX_APIKEY"  # From GitHub Secrets

cx scan create --project-name "ado-project" --branch "$BRANCH_NAME" -s "$REPO_URL" --scan-types "sast, sca" --report-format json --report-format summaryHTML --output-name "ado-report" --output-path "." --report-pdf-email hiren.soni46@yahoo.com --report-pdf-options sast --ignore-policy --debug
