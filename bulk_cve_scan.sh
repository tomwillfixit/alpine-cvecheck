#!/bin/bash

IMAGE_LIST=$1
TIMESTAMP=`date +"%T"`

if [ -z ${IMAGE_LIST} ];then
    echo "Please provide a textfile with a list of images"
    exit 1
fi

[ -d results ] || mkdir results 
[ -d reports ] || mkdir reports 

#Start scan

echo "Beginning CVE scan of :"
echo "========================================"
cat ${IMAGE_LIST}
echo "========================================"

while read -r line
do
    image_name="$line"
    echo "Scanning : ${image_name}"

    cp Dockerfile.container_under_test Dockerfile
    sed -i "s/IMAGE_NAME/${image_name}/g" Dockerfile
    docker build -t container_under_test:latest --no-cache -f Dockerfile .
    docker run -t --rm -v ${PWD}/results:/results container_under_test:latest /bin/sh -c "mv /tmp/CVE.log /results/${image_name}.${TIMESTAMP}.CVE.log"
    echo "Results in : ./results/${image_name}.${TIMESTAMP}.CVE.log"

    number_of_cves=`cat ./results/${image_name}.${TIMESTAMP}.CVE.log |grep CVE |wc -l`
    if [ ${number_of_cves} -eq 0 ];then
        echo "==============================" >> reports/cve.report.${TIMESTAMP}
        echo -e "\e[32mNo CVE's found for image : ${image_name} \e[0m" >> reports/cve.report.${TIMESTAMP}
        echo "==============================" >> reports/cve.report.${TIMESTAMP}
    else
        echo "==============================" >> reports/cve.report.${TIMESTAMP}
	echo -e "\e[31m${number_of_cves} CVE's found for image : ${image_name} \e[0m" >> reports/cve.report.${TIMESTAMP}
        echo "Details in ${image_name}.CVE.log" >> reports/cve.report.${TIMESTAMP}
        echo "==============================" >> reports/cve.report.${TIMESTAMP}
    fi

done < "${IMAGE_LIST}"

cat reports/cve.report.${TIMESTAMP}
