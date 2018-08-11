#!/bin/sh

packages=$(<package-list.txt)

arch="amd64" #"amd64" or "i386" or "all" to install only a specific architectures packages or all

green='\033[0;32m'
light_green='\033[1;32m'
gray='\033[0;37m'
end_color='\033[0m'

echo -e "${green}Starting NGINX apt cache ${end_color}"

cd /repo/debs

echo -e "${green}Checking for release files...${end_color}"

if [ ! -f Packages.gz ]; then
  echo -e "${green}No package file found. It's going to be a while. Grab a cup of coffee ${end_color}"

  function getDepends () { #clean list of depends for any given package
    apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends $1 | grep "^\w" | sort -u
  }

  echo -e "${green}Downloading the packages: $packages and their depends${end_color}"
  while read p; do
    echo -e "${green}Download core package: $p ${end_color}"
    apt-get download $p #download package itself
    for pkg in $(getDepends $p); do #download package depends, recommends, and suggests
      #quick and dirty check to save on storage space
      if [ $arch = "amd64" ] && [[ $pkg = *"i386"* ]] ; then
        echo -e "${gray}Skipping $pkg! Wrong architechture${end_color}"
      elif [ $arch = "i386" ] && [[ $pkg = *"amd64" ]]  ; then
        echo -e "${gray}Skipping $pkg! Wrong architechture${end_color}"
      else
        echo -e "${light_green}Download depend: $pkg${end_color}"
        apt-get download $pkg
      fi
    done
  done <<< "$packages"

  echo -e "${green}Updating the package file${end_color}"

  dpkg-scanpackages . | gzip -9c > Packages.gz

else
  echo -e "${green}Looks like we've already got all our package downloads! ${end_color}"
fi

cd /repo/cowrie
if [ ! -f cowrie.tar.gz ]; then
  rm -rf cowrie
  echo -e "${green}A local version of cowrie was no found. Downloading...${end_color}"
  git clone https://github.com/cowrie/cowrie.git
  tar -czvf cowrie.tar.gz cowrie
else
  echo -e "${green}Looks like a local version of cowrie is already archived. Moving on...${end_color}"
fi 

echo -e "${green}Copying files to ramdisk, please wait...${end_color}"

mkdir /usr/share/nginx/html/repo && cp -r /repo/debs/* /usr/share/nginx/html/repo
mkdir /usr/share/nginx/html/cowrie && cp -r /repo/cowrie/cowrie.tar.gz /usr/share/nginx/html/cowrie

echo -e "${green}Starting Nginx....${end_color}"

nginx;
