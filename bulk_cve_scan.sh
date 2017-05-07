#!/bin/bash

# Disclaimer. This was thrown together and does not reflect the quality of my code in real life ;)

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
    image_sha=$(docker image inspect --format "{{.ID}}" ${image_name})
    created=$(docker image inspect --format "{{.Created}}" ${image_name})

    echo "*************************************" >> reports/cve.report.${TIMESTAMP}
    echo "---> Image   : ${image_name}" >> reports/cve.report.${TIMESTAMP}
    echo "---> Sha     : ${image_sha}" >> reports/cve.report.${TIMESTAMP}
    echo "---> Created : ${created}" >> reports/cve.report.${TIMESTAMP} 
 
    cp Dockerfile.container_under_test Dockerfile
    sed -i "s/IMAGE_NAME/${image_name}/g" Dockerfile
    docker build -t container_under_test:latest --no-cache -f Dockerfile .
    docker run -t --rm -v ${PWD}/results:/results container_under_test:latest /bin/sh -c "mv /tmp/CVE.log /results/${image_name}.${TIMESTAMP}.CVE.log"
    echo "---> Results in : ./results/${image_name}.${TIMESTAMP}.CVE.log"

    number_of_cves=`cat ./results/${image_name}.${TIMESTAMP}.CVE.log |grep CVE |sort |uniq |wc -l`

    if [ ${number_of_cves} -eq 0 ];then
        echo "---> Log     : ./results/${image_name}.CVE.log" >> reports/cve.report.${TIMESTAMP}
        echo -e "\e[32m---> Status  : No CVE's found\e[0m" >> reports/cve.report.${TIMESTAMP}
    else
        echo "---> Log     : ./results/${image_name}.CVE.log" >> reports/cve.report.${TIMESTAMP}
	echo -e "\e[31m---> Status  : ${number_of_cves} CVE's found\e[0m" >> reports/cve.report.${TIMESTAMP}

        awk '{for(i=1;i<=NF;i++){if($i~/CVE/){print $i}}}' ./results/${image_name}.${TIMESTAMP}.CVE.log | tr -d '()' > stripped_cve.txt
        cat stripped_cve.txt |sort |uniq > stripped_cve_uniq.txt
        echo "" >> reports/cve.report.${TIMESTAMP}
        while read -r cve 
        do
            echo "	https://cve.mitre.org/cgi-bin/cvename.cgi?name=${cve}" >> reports/cve.report.${TIMESTAMP} 	

        done < stripped_cve_uniq.txt
        echo "" >> reports/cve.report.${TIMESTAMP}
    fi

    echo "*************************************" >> reports/cve.report.${TIMESTAMP}

done < "${IMAGE_LIST}"

cat reports/cve.report.${TIMESTAMP}
