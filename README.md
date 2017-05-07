# CVE Scanning of Alpine base images using Multi Stage builds in Docker 17.05  

![data](img/data.jpg)

The tl;dr of this post is that I want to scan my Alpine based images locally for vulnerabilities before pushing the image to an online registry. Why? Well I think it makes sense that developers have the option of checking for CVE's locally and at build time. They may choose to ignore the results but it's nice to have the option.  In future this could perhaps be made into a plugin or included with the docker build function.

I mentioned this to a few folks at DockerCon and decided to put together a simple demo.  Using the MultiStage build feature in Docker 17_05 we can append a CVE scan stage into our build and run a scan at build time.

## Step 1

Build the cvechecker image. This image will contain the cvechecker tool and the CVE database. More details on cvechecker can be found [here](https://github.com/sjvermeu/cvechecker/)

```
docker build -t cvechecker:latest .

```

## Step 2

There are lots of ways to run the CVE scan. Firstly let's try using the MultiStage Dockerfile to build a Wordpress container and then run the scan.

```
docker build -t wordpress:latest --no-cache -f Dockerfile.wordpress .

```

Copy the CVE.log from the image and check inside

```
docker run -t --rm -v ${PWD}:/results wordpress:latest /bin/sh -c "mv /tmp/CVE.log /results/wordpress.CVE.log"
```

### Example output

```
File "/usr/lib/libbz2.so.1.0.6" (CPE = cpe:/a:bzip:bzip2:1.0.6:::) on host 837a64dcc771 (key 837a64dcc771)
  Potential vulnerability found (CVE-2016-3189)
  CVSS Score is 4.3
  Full vulnerability match (incl. edition/language)

```

This CVE was detected in the libarchive package. This package is not needed and was just an example. Remove libarchive from the Dockerfile and rebuild. No vulnerability found. Great job.

## Step 3

Using the MultiStage Dockerfile we can supply a list of images and scan them all sequentially for CVE's.  We could use docker-compose to replace the image name as an environment variable but in this case we will just use a bit of bash.

```
./bulk_cve_scan.sh list_of_images.txt

```

This will pull each image, copy the contents into the cvechecker image, generate a list of executables and run the cvechecker. A results file is created per image and a final report is created.

### Example output

```
*************************************
---> Image   : nginx:1.13.0-alpine-perl
---> Sha     : sha256:dcf49000bf50c4e93d6cc84c96f8acf985998154e09f6301cff7c62314811604
---> Created : 2017-04-25T17:25:05.511678526Z
---> Log     : ./results/nginx:1.13.0-alpine-perl.CVE.log
---> Status  : 1 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189

*************************************
*************************************
---> Image   : redis:3.2.8-alpine
---> Sha     : sha256:83638a6d3af20698d5e207febe714ac46a23a98e1d86ba36fe502fadc788daa3
---> Created : 2017-03-03T23:33:08.415849842Z
---> Log     : ./results/redis:3.2.8-alpine.CVE.log
---> Status  : No CVE's found
*************************************
*************************************
---> Image   : logstash:1.5.6-alpine
---> Sha     : sha256:6a7afab35097ffcacf6445366065b234371902240e2d9bf41bb3d64386352db6
---> Created : 2017-03-07T18:57:08.447747089Z
---> Log     : ./results/logstash:1.5.6-alpine.CVE.log
---> Status  : 1 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189

*************************************
*************************************
---> Image   : logstash:1-alpine
---> Sha     : sha256:6a7afab35097ffcacf6445366065b234371902240e2d9bf41bb3d64386352db6
---> Created : 2017-03-07T18:57:08.447747089Z
---> Log     : ./results/logstash:1-alpine.CVE.log
---> Status  : 1 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189

*************************************
*************************************
---> Image   : elasticsearch:1.7.6-alpine
---> Sha     : sha256:59103e15fe949d9735eb4ff885abb6fb5ff50bc587acb4075ac10c0d9bbb0467
---> Created : 2017-04-04T23:28:36.351775037Z
---> Log     : ./results/elasticsearch:1.7.6-alpine.CVE.log
---> Status  : 1 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189

*************************************
*************************************
---> Image   : wordpress:4.7.4-php7.1-fpm-alpine
---> Sha     : sha256:80052e2343db98ce7ccf00b582fe024b40e07a497fdcc43f5814ba93b960d2d2
---> Created : 2017-05-06T00:15:39.364168997Z
---> Log     : ./results/wordpress:4.7.4-php7.1-fpm-alpine.CVE.log
---> Status  : 46 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-0903
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-1516
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-1517
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-1518
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-2753
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-3469
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-3486
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-4031
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2006-4226
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-1420
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-2583
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-2691
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-2692
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-6303
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-6304
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-2079
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-3963
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-4098
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-7247
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-2446
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-4019
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-4028
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2009-5026
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-1848
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-1849
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-1850
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3677
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3682
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3833
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3834
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3836
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3837
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-3838
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0075
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0087
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0101
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0102
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0114
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0484
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0490
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-1696
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-1697
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-3160
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-3166
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-3177
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-6321

*************************************
*************************************
---> Image   : ruby:2.1.8-alpine
---> Sha     : sha256:f6611d75e6dc337005a23816143cfa40f96fab41860f563665c36efbb541b1e6
---> Created : 2016-03-30T21:01:49.675295954Z
---> Log     : ./results/ruby:2.1.8-alpine.CVE.log
---> Status  : 14 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2105
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2106
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2107
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2109
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2176
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2177
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2178
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2179
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2180
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2181
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-2182
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-6302
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-6303

*************************************
*************************************
---> Image   : consul:v0.7.0
---> Sha     : sha256:2ba9010ee3cc0251be45e8b55f3154eb421df841cd93a375f9f5ab334d848291
---> Created : 2016-10-18T22:59:58.369872799Z
---> Log     : ./results/consul:v0.7.0.CVE.log
---> Status  : No CVE's found
*************************************
*************************************
---> Image   : python:3.4.5-alpine
---> Sha     : sha256:0eb0091592b3d8aab929e19041330d307e0e3302cf58ae8753276a2860c45037
---> Created : 2016-12-27T21:39:19.757995673Z
---> Log     : ./results/python:3.4.5-alpine.CVE.log
---> Status  : 1 CVE's found

	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189

*************************************
*************************************
---> Image   : rabbitmq:3.6.6-alpine
---> Sha     : sha256:1f17c5fffd2d35099050f4d224be92c424b90550cc65c76570be71d368e637cc
---> Created : 2017-03-03T23:32:16.463770425Z
---> Log     : ./results/rabbitmq:3.6.6-alpine.CVE.log
---> Status  : No CVE's found
*************************************

```

# Summary

I like free stuff. This isn't bullet-proof but it's already found a few questionable images which I would have just used without checking for potential issues.

I'll tidy this up in the coming weeks and perhaps use Goss as a trigger for the CVE check.

Feel free to contact me for more details, banter, pull requests etc

@tomwillfixit @Shipitcon @DockerDublin


