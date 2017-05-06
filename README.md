# Poor Man's Notary

![data](img/data.jpg)

In Sun/Oracle we would often put together prototypes and they would be called "A poor man's X".  I'm not really sure why but it kind of stuck.  The tl;dr of this post is that I want to scan my Alpine based images locally for vulnerabilities before pushing the image to an online registry.

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

## Step 3

Using the MultiStage Dockerfile we can supply a list of images and scan them all sequentially for CVE's.  We could use docker-compose to replace the image name as an environment variable but in this case we will just use a bit of bash.

```
./bulk_cve_scan.sh list_of_images.txt

```

This will pull each image, copy the contents into the cvechecker image, generate a list of executables and run the cvechecker. A results file is created per image and a final report is created.

### Example output

```
==============================
1 CVE's found for image : nginx:1.13.0-alpine-perl 
Details in nginx:1.13.0-alpine-perl.CVE.log
==============================
==============================
No CVE's found for image : redis:3.2.8-alpine 
==============================
==============================
1 CVE's found for image : logstash:1.5.6-alpine 
Details in logstash:1.5.6-alpine.CVE.log
==============================
==============================
1 CVE's found for image : logstash:1-alpine 
Details in logstash:1-alpine.CVE.log
==============================
==============================
1 CVE's found for image : elasticsearch:1.7.6-alpine 
Details in elasticsearch:1.7.6-alpine.CVE.log
==============================
==============================
46 CVE's found for image : wordpress:4.7.4-php7.1-fpm-alpine 
Details in wordpress:4.7.4-php7.1-fpm-alpine.CVE.log
==============================
==============================
56 CVE's found for image : ruby:2.1.8-alpine 
Details in ruby:2.1.8-alpine.CVE.log
==============================
==============================
No CVE's found for image : consul:v0.7.0 
==============================
==============================
1 CVE's found for image : python:3.4.5-alpine 
Details in python:3.4.5-alpine.CVE.log
==============================
==============================
No CVE's found for image : rabbitmq:3.6.6-alpine 
==============================

```

# Summary

I like free stuff. This isn't bullet-proof but it's already found a few questionable images which I would have just used without checking for potential issues.

I'll tidy this up in the coming weeks and perhaps use Goss as a trigger for the CVE check.

Feel free to contact me for more details, banter, pull requests etc

@tomwillfixit @Shipitcon @DockerDublin


