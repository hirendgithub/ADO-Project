#!/bin/bash

CLI='C:\ast-cli_2.3.21_linux_x64'

read -p "Enter your project name: " Project_Name
echo "Your project name is , $Project_Name"
read -p "Enter your Branch name: " Branch_Name
echo "Your Branch name is , $Branch_Name"
#read -p "Enter Your Group Name: " Group_Name
#echo "Your Group Name is , $Group_Name"
read -p "Enter your Repo URL: " REPO_URL
echo "Repo URL is , $REPO_URL "

timestamp=$(date +"%d_%m_%Y_%H_%M_%S")

# Create report name
Report_name="demo_project_$timestamp"

Project_Path="C:/Hiren/Project"

cd $Project_Path

echo "---789this is testing phase"

git clone "$REPO_URL"

echo "---789this is testing phase"


#git checkout $Branch_Name

echo "This is debugging 2"

cd $CLI

echo "This is debugging 3"

cx configure set --prop-name 'cx_base_uri' --prop-value 'https://deu.ast.checkmarx.net/'

cx configure set --prop-name 'cx_base_auth_uri' --prop-value 'https://deu.iam.checkmarx.net/'

cx configure set --prop-name 'cx_tenant' --prop-value 'cx-cs-na-pspoc'

cx configure set --prop-name 'cx_apikey' --prop-value 'eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NmM5YThiYy0xYTliLTQyNjItOGRhNi1hM2M0MGE4YWJhMzYifQ.eyJpYXQiOjE3NDg5NTM2MjksImp0aSI6ImE0ZmJmZTZlLTc1NWUtNDRkMC04MWUyLTM1MDMwZDhjYjY1OSIsImlzcyI6Imh0dHBzOi8vZGV1LmlhbS5jaGVja21hcngubmV0L2F1dGgvcmVhbG1zL2N4LWNzLW5hLXBzcG9jIiwiYXVkIjoiaHR0cHM6Ly9kZXUuaWFtLmNoZWNrbWFyeC5uZXQvYXV0aC9yZWFsbXMvY3gtY3MtbmEtcHNwb2MiLCJzdWIiOiJlYTlmMDc0YS1jOGMxLTQ3ODgtYjg0YS01ZDQ1MjZmMWVmYTMiLCJ0eXAiOiJPZmZsaW5lIiwiYXpwIjoiYXN0LWFwcCIsInNpZCI6ImYwZDBiYzUzLTU2OTgtNDg0Mi1iN2FiLTc5YzY5NjU2ZTBlNCIsInNjb3BlIjoicm9sZXMgcHJvZmlsZSBhc3QtYXBpIGlhbS1hcGkgZW1haWwgb2ZmbGluZV9hY2Nlc3MifQ.MiALYYrbUCxuBRz_VxlyOepeRSwn_5ZZtCVsXwP70i6XBGjq4ohXKxq_zBLw5ClWVpSHI6LlDBholNP_EjkdVg'

echo "This is debugging 4"

cx scan create --project-name "$Project_Name" --branch "$Branch_Name" -s "$Project_Path" --scan-types "sast" --report-format json --report-format summaryHTML --output-name "$Report_name" --output-path "." --report-pdf-email hiren.soni46@yahoo.com --report-pdf-options sast --ignore-policy --debug

# echo "Captured Scan ID: $SCAN_ID"

echo "This is debugging 5"



ATTACHMENT_PATH="$CLI/$Report_name.html"


powershell -Command "
\$smtpServer = 'smtp.gmail.com'
\$smtpPort = 587
\$from = 'hirendhakan8080@gmail.com'
\$to = 'hiren.soni46@yahoo.com'
\$subject = 'Project Scan Summary'
\$body = 'This email includes an attachment of project summary.'
\$username = 'hirendhakan8080@gmail.com'
\$password = ConvertTo-SecureString 'ndmr jelr rioq oiuk' -AsPlainText -Force
\$cred = New-Object System.Management.Automation.PSCredential(\$username, \$password)
Send-MailMessage -From \$from -To \$to -Subject \$subject -Body \$body -SmtpServer \$smtpServer -Port \$smtpPort -UseSsl -Credential \$cred -Attachments '${ATTACHMENT_PATH}'
"
echo $ATTACHMENT_PATH
echo "Script has finished successfully"

#./cx scan create --project-name "$PROJECT_NAME" --branch "$BRANCH_NAME" -s "$REPO_URL"
## Output of above pring " Scan created successfully. Scan ID: 12345678"  We need to parse can id and pass in below command store in s

##  sleep 10 
# wait for 10 sec

## ./cx results show --scan-id $SCAN_ID= --report-format=json --output-name report.json
#--project-groups $Group_Name

#echo "$body" | mailx -s "$subject" -a "$attachment" "$to"
