#!/bin/bash
#FILE=$1
FOLDER_LIST=/root/work/folder_list.txt
FILE_LIST=/root/work/file_list.txt
OUTPUT_FILE=/root/work/output_sipSDK.txt
SOURCE='/root/work'
FUNCTION_LIST=/root/work/it6/function_list.txt

API_NAME="ERR_STATE_free_strings"
pattern=sip


echo > $OUTPUT_FILE
CURR_DIR=`pwd`

cd $SOURCE
for fld in `cat ${FOLDER_LIST}`
do
	cd $fld
	echo "******************${fld}***********************" | tee -a $OUTPUT_FILE
	grep -nsi --include "*.cpp" --include "*.h" sip * | tee -a $OUTPUT_FILE
	sleep 3
	cd $SOURCE
done
cd $CURR_DIR

cd ${SOURCE}
for fl in `cat ${FILE_LIST}`
do
	echo "******************${fl}***********************" 
	echo "******************${fl}***********************" | tee -a $OUTPUT_FILE
	grep -ni sip KM3/${fl} | tee -a $OUTPUT_FILE
	sleep 2
done
cd $CURR_DIR

#cat output_sipSDK.txt |  sed -e "s/[[:space:]]\+/ /g" > /root/work/output_sipSDK_2.txt