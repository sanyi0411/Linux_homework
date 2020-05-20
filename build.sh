#!/bin/bash

#Parsing the config file with jq:
URL="https://github.com/$(jq -r .git.user config.json)/$(jq -r .git.repo config.json).git"
REPO=$(jq -r .git.repo config.json)
ENTRY=$(jq -r .git.entry config.json)
BRANCH=$(jq -r .git.branch config.json)
CXX=$(jq -r .build.compiler config.json)
VER=$(jq -r .build.version config.json)
START=$(pwd)
SUC=?

upload () {
	SUC=$1
	echo -e "\e[93m***Uploading results***\e[0m"
	cd $START
	if [[ ! -d "Linux_homework" ]]
	then
		git clone "https://github.com/sanyi0411/Linux_homework.git"
	fi
	
	cd Linux_homework
	
	if [[ $SUC -eq "succ" ]]
	then
		sed -i "s/<br>/<tr>\n<td>$REPO<\/td>\n<br>/g" report.html
		sed -i "s/<br>/<td>$(date)<\/td>\n<br>/g" report.html
		sed -i "s/<br>/<td style="background-color:green">Successful<\/td>\n<\/tr>\n<br>/g" report.html
	else
		echo ""
	fi
	
	git add .
	git commit -m "Upload build results"
	git push origin master
}

send_notification() {
	cd $START
	rm -f email.txt 2> /dev/null
	echo "Last build: $SUC \nYou can check the results at\nhttps://htmlpreview.github.io/?https://github.com/sanyi0411/Linux_homework/blob/master/report.html" >> email.txt
	for email in $(jq -r .emails[] config.json)
	do
		sendmail $email < email.txt 2>/dev/null
	done
}

rm -r -f $REPO 2> /dev/null

git clone $URL

cd $REPO

git checkout $BRANCH
git pull

eval "$CXX $ENTRY -o build.out"
if [[ $? -eq 0 ]]
then 
	echo -e "\e[92m***Build successful***\e[25m"
	upload succ
	send_notification
else
	echo -e "\e[5m\e[91m***Build failed***\e[0m"
	upload fail
	send_notification
fi

