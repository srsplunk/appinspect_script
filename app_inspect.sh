SPLUNK_USERNAME=<YOUR_SPLUNKDOTCOM_USERNAME>
tgz_file=$1
response=$(curl -u ${SPLUNK_USERNAME} --url "https://api.splunk.com/2.0/rest/login/splunk")
token=$(echo $response|jq '.data.token')
#strip double quotes from start and end:
tok="${token%\"}"
tok="${tok#\"}"

echo "Performing app inspect on: "${tgz_file}
#submit file to app inspect:
app_inspect_response=$(curl -X POST \
    -H "Authorization: bearer "${tok} \
    -H "Cache-Control: no-cache" \
    -F "app_package=@${tgz_file}" \
    -F "included_tags=cloud" \
    --url "https://appinspect.splunk.com/v1/app/validate")

echo ${app_inspect_response}
echo ${app_inspect_response}|jq
echo ${app_inspect_response}|jq '.request_id'

#check status of request
request_id=$(echo ${app_inspect_response}|jq '.request_id')
status=$(echo ${app_inspect_response}|jq '.status')
#strip double quotes
req="${request_id%\"}"
req="${req#\"}"
echo "Request ID: ${req}"
status=\"PROCESSING\"

while [ $status = \"PROCESSING\" ]
do

	request_status_response=$(curl -X GET \
    	-H "Authorization: bearer "${tok} \
	--url "https://appinspect.splunk.com/v1/app/validate/status/${req}")
	status=$(echo ${request_status_response}|jq '.status')
	echo $status
sleep 5
done
echo $request_status_response

#download the report:
curl -X GET \
         -H "Authorization: bearer ${tok}" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/${req}" > app_inspect_report_${req}.html


