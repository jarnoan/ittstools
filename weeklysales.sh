#!/bin/sh

TMPDIR=/tmp/itunesconnect
COOKIES=${TMPDIR}/cookies
REPORTSDIR=${HOME}/itunesreports
MAIL="me@my.mail"
MAILCC="them@their.mails"

USERNAME=my@apple.id
PASSWORD=mypassword

ENTRYURL=https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa
LOGINURL=https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wo/0.0.5.3.3.2.1.1
SALESURL=https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wo/2.0.5.7.2.7.1.0.0.3
REPORTSURL=https://itts.apple.com/cgi-bin/WebObjects/Piano.woa

mkdir -p $TMPDIR
chmod go-rx $TMPDIR
mkdir -p $REPORTSDIR

wget --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --output-document=${TMPDIR}/entry.html \
     $ENTRYURL 

wget --load-cookies=$COOKIES \
     --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --post-data="theAccountName=${USERNAME}&theAccountPW=${PASSWORD}&1.Continue.x=53&1.Continue.y=13&theAuxValue=" \
     --output-document=${TMPDIR}/login.html \
     $LOGINURL

wget --load-cookies=$COOKIES \
     --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --output-document=${TMPDIR}/sales.html \
     $SALESURL

wget --load-cookies=$COOKIES \
     --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --output-document=${TMPDIR}/reports.html \
     $REPORTSURL

SID=`grep PianoAppSID $COOKIES | gawk '{ print $7 }'`
REPORTURL=`grep '<form method="post" name="frmVendorPage"' ${TMPDIR}/reports.html | gawk '{ match($0, /action="(.*)"/, arr) ; print arr[1] }'`

wget --load-cookies=$COOKIES \
     --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --output-document=${TMPDIR}/reports1.html \
     --post-data="17.9=Summary&17.11=Weekly&17.13.1=03%2F21%2F2010&hiddenDayOrWeekSelection=Weekly&hiddenSubmitTypeName=ShowDropDown&wosid=${SID}" \
     https://itts.apple.com${REPORTURL}

REPORTURL=`grep '<form method="post" name="frmVendorPage"' ${TMPDIR}/reports1.html | gawk '{ match($0, /action="(.*)"/, arr) ; print arr[1] }'`
URLDATE=`date -d 'last sunday' '+%m%%2F%d%%2F%Y'`
REPORTFILE=${TMPDIR}/report.csv.gz
wget --load-cookies=$COOKIES \
     --save-cookies=$COOKIES \
     --keep-session-cookies \
     --quiet \
     --output-document=${REPORTFILE} \
     --post-data="17.9=Summary&17.11=Weekly&17.15.1=${URLDATE}&hiddenDayOrWeekSelection=${URLDATE}&hiddenSubmitTypeName=Download&wosid=${SID}" \
     https://itts.apple.com${REPORTURL}

FILEDATE=`date -d 'last sunday' '+%F'`
zcat $REPORTFILE > ${REPORTSDIR}/${FILEDATE}.csv
zcat $REPORTFILE | tail +2 >> ${REPORTSDIR}/all_reports.csv
zcat $REPORTFILE | mail -s "iTunes report $FILEDATE" -c $MAILCC $MAIL

