#!/bin/bash
#FILE=$1
FOLDER_LIST=/root/work/folderlist.txt
FILE_LIST=/root/work/filelist.txt
OUTPUT_FILE=/root/work/output_check_script.txt
SOURCE='/root/work'
KM3=${SOURCE}/KM3
FUNCTION_LIST=/root/work/it6/function_list.txt

API_NAME="ERR_STATE_free_strings"
pattern=PageScopeMobile


echo > $OUTPUT_FILE
CURR_DIR=`pwd`

cd $KM3
for fld in `cat ${FOLDER_LIST}`
do
	cd $fld
	echo "******************${fld}***********************" | tee -a $OUTPUT_FILE
	grep -nasi --include=*.cpp --include=*.h --include=Media* ${pattern} * | tee -a $OUTPUT_FILE
	sleep 3
	cd $KM3
done
cd $CURR_DIR

cd ${SOURCE}
for fl in `cat ${FILE_LIST}`
do
	echo "******************${fl}***********************" 
	echo "******************${fl}***********************" | tee -a $OUTPUT_FILE
	grep -nai ${pattern} KM3/${fl} | tee -a $OUTPUT_FILE
	sleep 2
done
cd $CURR_DIR

#cat output_check_script.txt |  sed -e "s/[[:space:]]\+/ /g" > /root/work/output_check_script_2.txt