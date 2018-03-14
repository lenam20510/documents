#!/bin/bash
# clear
start=`date +%s`
start_time=`date +%F_%H%M%S`
#Default value:
PARAMS=$@
CURR_DIR=`pwd`
EXTEN_FILES='-name *.h -o -name *.cpp -o -name Makefile -o -name MediaMapFile*'
USER=hemfpadmin
HOME=/home/$USER
ARCH_FLD=${HOME}/arch

MODEL_NAME=Poseidon
MACHINE_TYPE=z5b7
ACTION=act2
QT_VERSION=q530

KM3=$CURR_DIR/${MODEL_NAME}/KM3
KM=$KM3/KM
KM_WORK=${KM}/work
logFolder=`echo ${KM_WORK}/${MACHINE_TYPE}* | cut -d ' ' -f1`/log

SUFFIX="e r n"

function backupLogs {
	echo "-->Backuping logs..."
	ls $logFolder/*.log >> /dev/null
	if [ $? -ne 0 ]; then
		return
	fi
	prefix=${start_time}
	backupLogFolder=$logFolder/backup_log-${prefix}
	mkdir -p $backupLogFolder
	echo "Moving all logs to $backupLogFolder"
	mv $logFolder/*.log $backupLogFolder
	mv $logFolder/*.txt $backupLogFolder
}

function checkEnvBuild {
	local status=True
	cd ${ARCH_FLD}
	fld_Qt=`echo qt-everywhere* | cut -d ' ' -f1`;			echo fld_Qt:$fld_Qt
	fld_Xorg=`echo Xorg* | cut -d ' ' -f1`;					echo fld_Xorg:$fld_Xorg
	[[ ! -d $fld_Qt || ! -d $fld_Xorg ]] && echo "fld_Qt OR fld_Xorg don't exist" && status=False
	cd $CURR_DIR
	[[ ! -d $KM/pmake ]] && echo "pmake folder don't exist." && status=False
	[[ "$status" == "True" ]] && return 0
	return 1
}

function startBuild {
	check=`ps -ef | grep pmake.sh | grep -v grep`
	[ $? -ne 0 ] && echo "There exists a another progress that is running. Exit!!!" && exit 0
	checkEnvBuild
	[ $? -ne 0 ] && echo "setupEnvBuild is't good." && exit 0
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	echo "-->Build server starting..."
	build_log=$logFolder/build-log-$start_time.txt
	error_log=$logFolder/errors.txt
	#start build
	cd $KM/pmake
	echo "./pmake.sh $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX}"
	$(./pmake.sh $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX} | tee -a $build_log) &
	sleep 5
	loop=true
	while [[ -n "$loop" ]]; do
		id=`ps -ef | grep -v "grep" | grep ./pmake.sh`
		if [ $? -ne 0 ]; then
			loop=""
		else
			curr=`date +%s`
			let deltatime=curr-start
			let hours=deltatime/3600
			let minutes=(deltatime/60)%60
			let seconds=deltatime%60
			printf "*************************%d:%02d:%02d*****************************\n" $hours $minutes $seconds
			# errors=`find $logFolder/*.log | xargs grep --color=auto "error:"`
			errors=`egrep -in --color=always -e "error:" -e " error " -e " error$" -e "^error " ${build_log}`
			echo "$errors"
			if [[ -n "$errors" && "$errors" == *"error:"* ]]; then
				echo "`grep -n --color=always "error:" ${build_log}`" > $error_log &
			fi
			echo
		fi
		sleep 30
	done
	printf "Total build time ($MACHINE_TYPE): %d:%02d:%02d\n" $hours $minutes $seconds
	`egrep -in --color=always -e "error:" -e " error " -e " error$" -e "^error " ${build_log}`
	cd $CURR_DIR
	exit 0
}

function setupEnvBuild {
	cd $CURR_DIR
##Procedure of Construct the BuildEnv
	#Checking exists of necessary files.
	file_BuildEnv=`echo *${MODEL_NAME}*.bz2 | cut -d ' ' -f1`;	echo file_BuildEnv:$file_BuildEnv
	file_Qt=`echo qt-everywhere*.bz2 | cut -d ' ' -f1`;			echo file_Qt:$file_Qt
	file_Xorg=`echo Xorg*.bz2 | cut -d ' ' -f1`;				echo file_Xorg:$file_Xorg
	file_Subset=`echo mkindex*.sh | cut -d ' ' -f1`;			echo file_Subset:$file_Subset
	file_qt_chg=qt_chg.sh;										echo file_qt_chg:$file_qt_chg
	[[ ! -f $file_BuildEnv || ! -f $file_Qt || ! -f $file_Xorg || \
	! -f $file_Subset || ! -f $file_qt_chg || ! -f u4e ]] && echo FAILED && STATUS=False && exit
	#Uncompress the BuildEnv, Qt, Xorg file on Build server.
	echo "-->Uncompress the BuildEnv, Qt, Xorg file on Build server."
	# echo "tar jxvf $file_Qt " ; tar jxvf $file_Qt &
	# echo "tar jxvf $file_Xorg " ; tar jxvf $file_Xorg &
	# echo "tar jxvf $file_BuildEnv " ; tar jxvf $file_BuildEnv; 
	
	echo "-->Rename the Qt, Xorg path in Makefile, sh files."
	[ ! -d $MODEL_NAME ] && echo "MODEL_NAME don't exist" && STATUS=False && exit
	# ./qt_chg.sh $MODEL_NAME/KM3 1
	echo "-->Move the Qt, Xorg directory to ~/arch directory:."
	fld_Qt=`echo qt-everywhere* | cut -d ' ' -f1`;			echo fld_Qt:$fld_Qt
	fld_Xorg=`echo Xorg* | cut -d ' ' -f1`;					echo fld_Xorg:$fld_Xorg
	[[ ! -d $fld_Qt || ! -d $fld_Xorg ]] && echo "fld_Qt OR fld_Xorg don't exist" && STATUS=False && exit
	cp -rf $fld_Qt ${ARCH_FLD}; cp -rf $fld_Xorg ${ARCH_FLD};
}

STATUS=True
IS_setupEnvBuild=
IS_BuildServer=
IS_BackupLog=True
##Getting
#MACHINE_TYPE
# result=`ls ${KM_WORK} -l | grep ^d | head -1 | awk '{print $NF}'`
# echo Machine Type: $result

if [[ "$1" == "-h" ]]; then
	Help
	exit 0
else #Start build
	while [[ -n "$1" ]]; do
		if [[ "$1" == "-a" ]]; then
			shift
			ACTION=$1
		elif [[ "$1" == "-m" ]]; then
			shift
			MACHINE_TYPE=$1
			logFolder=`echo ${KM_WORK}/${MACHINE_TYPE}* | cut -d ' ' -f1`/log
		elif [[ "$1" == "-notbl" ]]; then
			IS_BackupLog=
		elif [[ "$1" == "-se" ]]; then
			IS_setupEnvBuild=True
		elif [[ "$1" == "-sb" ]]; then
			IS_BuildServer=True
		fi	
		shift
	done	
	echo action: $ACTION
	echo machine_type: $MACHINE_TYPE
	echo logFolder: $logFolder
	echo 
	# checking buildmfp.sh was existed or not
	check=`ps -ef | grep buildServer.sh | grep -v grep`
	[ $? -ne 0 ] && exit 0
	[[ "$IS_setupEnvBuild" == "True" ]] && setupEnvBuild
	[[ "$IS_BuildServer" == "True" && "$STATUS" == "True" ]] && startBuild
	exit 0
fi

# Added more files to Repository
#while IFS= read -r line ; do echo $line; cp --parents $line ~/work/git/IT5_42_ZeusS_ZX0_SIM/; done < ~/work/list_file

