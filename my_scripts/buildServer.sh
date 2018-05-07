#!/bin/bash
# clear
PPID=$$
echo PPID:$PPID
#Default value:
start=`date +%s`
start_time=`date +%F_%H%M%S`
BASENAME=`basename "$0"`
BASEDIR=`dirname $(readlink -f "$0")`

#Default value:
PARAMS=$@
CURR_DIR=`pwd`
EXTEN_FILES='-name *.h -o -name *.cpp -o -name Makefile -o -name MediaMapFile*'
# USER=hemfpadmin
# HOME=/home/$USER
# ARCH_FLD=${HOME}/arch

# MODEL_NAME=${MODEL_NAME:-ZeusS_ZX0}
# MACHINE_TYPE=${MACHINE_TYPE:-zsz}
# ACTION=act2
# QT_VERSION=q530
ROOT=$MY_WORK

KM3=$ROOT/${MODEL_NAME}/KM3
KM=$KM3/KM
KM_APP=$KM/application
KM_WORK=${KM}/work
# logFolder=`echo ${KM_WORK}/${MACHINE_TYPE}* | cut -d ' ' -f1`/log

# REPO_NAME=${REPO_NAME:-${MODEL_NAME}}
# REPO_PATH=${REPO_PATH:-"$BASEDIR/git/${REPO_NAME}"}
# REPO_PATH=$BASEDIR/git/${REPO_NAME}
COUNT_TRAP=0
export PID_PMAKE=

killBuildProcess () {
	# echo COUNT_TRAP:$COUNT_TRAP
	# [ $COUNT_TRAP -gt 0 ] && exit 0
	# COUNT_TRAP=$((COUNT_TRAP+1))
	nameProcess=${1:-${GCC}}
	while true; do
		pid=
		# ps -o comm,pid,uname -C xinit
		# ps -o pid,cmd -C xinit  | awk '{print $1,$3,$NF;}' | grep --color=auto xinit
		# ps -af | egrep -e i386-linux-gcc  | grep -v grep | awk '{print $2,$3,$8,$NF;}' > tmp
		# pid=`ps -ef | grep -v grep | grep ^$nameProcess | grep ^'gcc' | grep -v .c$ | grep -v .cpp$ | awk '{print $2;}'`
		# pid=`ps -o pid,cmd -C $nameProcess | awk '{print $1,$2,$3,$NF;}' | grep --color=auto $nameProcess`
		# echo "$pid" | grep -q $nameProcess
		pid=`ps -o time,pid,ppid,cmd --forest -g -p $(pgrep -x $BASENAME) | grep -v grep | grep $nameProcess`
		if [[ $? -ne 0 ]]; then # || `ps -o pid,comm -C $PID_PMAKE | grep -v COMMAND` -ne 0
			break
		fi
		# echo "${nameProcess} is being used. Please wait..."
		echo "$pid" | awk '{print $2,$3,$7,$8,$9,$(NF-1),$NF}'
		echo "--------------------------------------------"
		# echo "$pid" | grep --color=auto $nameProcess | awk '{print $2,$3,$7,$(NF-1),$NF}'
		sleep 3
	done
	# echo "$pid" | awk '{print $2,$3,$7,$(NF-1),$NF}'
	# echo "Safe kill process!!"
	killHardProcess
}
trap killHardProcess SIGINT
killHardProcess() {
	echo "killHardProcess!!!"
	pids=$(pgrep $BASENAME | grep -v grep | grep -v $PPID)
	for pid in $pids
	do
		echo $pid
		kill -9 $pid&
	done
	exit 0
}

SUFFIX="e r n 4"

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

function updateSource {
	echo "-->Updating source..."
	local fileUpdateSource=${logFolder}/fileUpdateSource-`date +%F`.txt

	arr_upSource=(mfp divlib/client/Proxy/system divlib/server/Stub divlib/Tool)
	case ${ACTION} in
		divact2) arr_upSource=(divlib/client/Proxy/system/ divlib/server/Stub divlib/Tool);;
		mfpact2) arr_upSource=(mfp);;
		*) ;;
	esac
	ops_find='-name "*.h" -o  -name "*.cpp" -o -name Makefile -name "*.txt"'
	echo >> ${fileUpdateSource}
	echo fileUpdateSource:$fileUpdateSource
	cd ${REPO_PATH}
	
	subflds=`ls . -1 | grep -vE "/usr|^$"`
	if [[ "$subflds" == *"KM"* ]]; then
		cd KM/application
	elif [[ "$subflds" == *"application"* ]]; then
		cd application
	fi
	
	for path in ${arr_upSource[*]}
	do
		echo $path
		files=`find $path/* -type f ${EXTEN_FILES}`
		for file in ${files[*]}
		do
			file_name=$(basename "${file}")
			file_build_sour=$KM_APP/$file
			`cmp --silent $file $file_build_sour`
			if [ $? -ne 0 ]; then
				echo $file_build_sour | tee -a $fileUpdateSource
				dirname_file_build_sour=$(dirname "${file_build_sour}")
				# echo "Don't copy $file"
				mkdir -p $dirname_file_build_sour
				yes | cp -f $file $file_build_sour
				touch $file_build_sour
			fi
		done
	done
	cd $CURR_DIR
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

# $1: source folder
# $2: destination folder
# $3: list file
function addMoreFiles {
	echo "-->addMoreFiles..."
	local source=`readlink -f $1`
	local destination=`readlink -f $2`
	local file=`readlink -f $3`
	# echo source:$source
	# echo destination:$destination
	# echo file:$file
	[[ ! -d $source || ! -d $destination || ! -f $file ]] && echo "Failed" && return
	# content="`cat $file`"
	# mkdir -p ${destination}; #rm -rf ${destination}/*
	cd $source
	while IFS= read -r line
	do
		if [[ -n "$line" ]]; then
			if [ -f $line ]; then
				file_build_sour=${destination}/$line
				# echo "$line ${CURR_DIR}/${destination}/$line"
				# cp --parents $line ${CURR_DIR}/${destination}/
				dirname_file_build_sour=$(dirname "${file_build_sour}")
				# echo "Don't copy $file"
				mkdir -p $dirname_file_build_sour
				yes | cp -f $line $file_build_sour
				touch $file_build_sour
			else
				echo "File is not exist: $line"
			fi
		fi
	done < $file
	cd $CURR_DIR
}

function analysis_Revision {
	revision_begin=$1
	revision_end=$2
	# Set the latest revision
	source_OPA=
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
	
	#revision_end=""
	#revision_end="HEAD"
	if [[ "${revision_begin}" == "all" ]]; then
		if [[ "$branch" != "${MASTER_BRANCH}" ]]; then
			rev_list_branch=`git rev-list ${branch}`
			rev_list_master_branch=`git rev-list ^${MASTER_BRANCH} ${branch}`
			# get first commit of a branch
			# first_commit_branch=$(git rev-list ^${MASTER_BRANCH} ${branch} | tail -n 1)
			# get previous commit before the first commit of this branch.
			previous_commit=$(echo ${rev_list_branch} | cut -c$((${#rev_list_master_branch}+1))-)
			count=$(echo "$previous_commit" | wc -w)
			if [ $count -lt 2 ]; then
				previous_commit=$(echo $previous_commit | xargs )
			else
				previous_commit=$(echo $previous_commit | awk '{print $1;}' | xargs)
			fi
			revision_begin=${previous_commit}
		else
			revision_begin=`git rev-list ${branch} | tail -n1`
		fi
		revision_end=
	fi
	if [[ -z $revision_end && -z $revision_begin ]]; then
		revision_begin=HEAD
	fi
	echo revision_begin=$revision_begin
	echo revision_end=$revision_end
	cd ${CURR_DIR}
}

function extract_source {
	revision_begin=$1
	revision_end=$2
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`; [[ -z $branch ]] && branch=default
	des_folder=${BASEDIR}"/extract_source/[${REPO_NAME}]_${branch}"; mkdir -p $des_folder
	file_FirstCommit=$des_folder/file_FirstCommit.txt
	first_commit=`cat $file_FirstCommit`
	if [[ $revision_begin == all && -n $first_commit ]]; then
		echo OK
		revision_begin=$first_commit
		revision_end=
	else
		analysis_Revision $revision_begin $revision_end
		echo $revision_begin > $file_FirstCommit
	fi
	
	echo "------------------- $revision_begin:$revision_end ------------------------"
	# des_folder=${WORK}"/extract_source/`date +%F_%H%M%S`_${branch}_${revision_begin}_${revision_end}"
	# mv ${des_folder}-{,.}* ${des_folder} # Moving old extract-sources to backup folder.
	des_folder=${des_folder}"/${branch}-${revision_begin}-${revision_end}-`date +%F_%H%M%S`"
	mkdir -p $des_folder
	rm -rf $des_folder/*
	file_diff_name_only=$des_folder/file_diff_name_only.txt
	file_diff=$des_folder/diff_${revision_begin}_${revision_end}.patch
	old_folder=$des_folder/old
	new_folder=$des_folder/new
	# Cleanup & create destination folder.
	mkdir -p $old_folder
	mkdir -p $new_folder

	# This is one-line command to get list file from "revision_begin" to "revision_end".
	# And, perform copying changed files to new location by keep folder structure same as source file.
	# git diff 06a3af6 8174c67 --name-only
	cd ${REPO_PATH}
	git diff $revision_begin $revision_end > $file_diff
	git diff $revision_begin $revision_end --name-only > $file_diff_name_only
	# git diff $revision_begin $revision_end --name-only | 
	while read line
	do
		is_FailCommit=
		dir_name_file=$(dirname "${line}")
		mkdir -p $old_folder/$dir_name_file
		git show ${revision_begin}:$line > $old_folder/$line
		if [ $? -ne 0 ]; then # If having a error, we will find first commit of this file.
			is_FailCommit=True
			first_commit_line=$(git log --diff-filter=A -- ${line} | head -n1 | cut -d ' ' -f2)
			echo "first_commit_line:${first_commit_line}"
			rm -f $old_folder/$line
			git show ${first_commit_line}:$line > $old_folder/$line
		fi
		
		mkdir -p $new_folder/$dir_name_file
		if [[ -n $revision_end ]]; then
			git show ${revision_end}:$line > $new_folder/$line
		else
			cp $line $new_folder/$line
		fi
		
		if [[ "$is_FailCommit" == "True" ]]; then
			# Checking again
			`cmp --silent $new_folder/$line $old_folder/$line`
			if [ $? -eq 0 ]; then
				# The same, so remove it
				echo "Both files are the same. Remove them"
				rm -f $new_folder/$line $old_folder/$line
			fi
		fi
		# cp --parents ${REPO_PATH}/$line $new_folder
		# cp --parents $ORIGINAL_SOURCE/KM3/$line $old_folder
	done < "$file_diff_name_only"
	# Create_UT $file_diff
	# tree $old_folder
	# tree $new_folder
	# Show tree new_folder
	echo
	# addedLine=`diff -r old new | grep "> " | wc -l`
	changedLine=`git diff --stat $revision_begin HEAD`
	changedLine+=" => Actual Changed: "`git diff -w $revision_begin HEAD | grep -c -E "(^[+-]\s*(\/)?\*)|(^[+-]\s*\/\/)"`
	cd ${des_folder}
	find ./new | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
	# rm -f ${file_diff_name_only}; rm -f ${file_diff}
	echo "${changedLine}"
	showFile ${des_folder}

	cd $CURR_DIR
	echo "-----------------------------------------------------"
}

function showFile {
	echo '--------------------------->'
	echo '\\'${SERVER_IPaddress}`readlink -f ${1}` | sed -e s/home\\/hemfp// | sed  -e 's/\//\\/g'
	echo '<---------------------------'
}

function showInfoProcess {
	local name_proc=${1:-${PMAKE_FILE}}
	echo "-->showInfoProcess..."
	pro=
	# echo `ps axf | grep $name_proc | grep -v grep | grep -v buildServer.sh | awk '{print $1}'`
	for pro in `ps axf | grep -v grep | grep -v $BASENAME | grep $name_proc | awk '{print $1}'`
	do	
		info=`pwdx $pro`
		info+=" "`ps -p $pro -o args | tail -n1 | grep --color=always $name_proc`
		echo $info
	done
	echo "-------------------------------------"
}

function createRepository {
	echo "-->createRepository..."
	local fld_source=${1:-${KM_APP}}
	echo fld_source:$fld_source
	local file_listInCommon=`readlink -f listFileInCommonAPI.txt`
	local path_repo=$ROOT/git/${REPO_NAME}
	local path_repo_copy=${path_repo}/application; mkdir -p $path_repo_copy
	[ ! -d $fld_source ] && echo "fld_source is not exist" && return
	[ ! -f $file_listInCommon ] && echo "file_listInCommon is not exist" && return
	addMoreFiles $fld_source $path_repo_copy $file_listInCommon
	echo "initial repository..."
	git init $path_repo
	cd $path_repo
	git add ./*; git commit -m "initial"
	cd $CURR_DIR
}

runBuild() {
	echo "cd $KM/pmake"
	cd $KM/pmake
	echo "./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX}"
	$(./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX} | tee -a $build_log) &
	export PID_PMAKE=`echo $!`
	echo PID_PMAKE:$PID_PMAKE
}

function startBuild {
	# check=`ps -ef | grep pmake.sh | grep -v grep`
	# [ $? -ne 0 ] && echo "There exists a another progress that is running. Exit!!!" && exit 0
	# checkEnvBuild
	# [ $? -ne 0 ] && echo "setupEnvBuild is't good." && exit 0
	# showInfoProcess ${PMAKE_FILE} # show that other process's running.
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	echo "-->Build server starting..."
	# trap "checkInBuilding $$; exit 0" SIGINT SIGTERM
	# trap 'checkInBuilding; exit 0' SIGINT SIGTERM
	build_log=$logFolder/build-log-`date +%F`.txt
	error_log=$logFolder/errors.txt
	showFile $build_log
	#start build
	# echo "cd $KM/pmake"
	# cd $KM/pmake
	# echo "./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX}"
	# $(./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} ${SUFFIX} | tee -a $build_log) &
	# PID_PMAKE=`echo $!`
	# echo PID_PMAKE:$PID_PMAKE
	runBuild
	sleep 5
	loop=true
	while [[ -n "$loop" ]]; do
		echo PID_PMAKE:$PID_PMAKE
		`ps -ef | grep -v grep | grep -q $PMAKE_FILE`
		if [ $? -ne 0 ]; then
			loop=""
			break
		else
			curr=`date +%s`
			let deltatime=curr-start
			let hours=deltatime/3600
			let minutes=(deltatime/60)%60
			let seconds=deltatime%60
			printf "*************************%d:%02d:%02d*****************************\n" $hours $minutes $seconds
			# errors=`find $logFolder/*.log | xargs grep --color=auto "error:"`
			# errors=`egrep -in --color=always -e "error:" -e " error " -e " error$" -e "^error " ${build_log}`
			errors=`egrep -in --color=auto -e "error:" ${build_log}`
			echo "$errors"
			if [[ -n "$errors" && "$errors" == *"error:"* ]]; then
				echo "`grep -n --color=auto "error:" ${build_log}`" > $error_log &
			fi
			echo
		fi
		showInfoProcess ${PMAKE_FILE} # show that other pmake process are running.
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
IS_UpdateSource=True
##Getting
#MACHINE_TYPE
# result=`ls ${KM_WORK} -l | grep ^d | head -1 | awk '{print $NF}'`
# echo Machine Type: $result

if [[ "$1" == "-h" ]]; then
	Help
	exit 0
elif [[ "$1" == "-amf" ]]; then #Added more files
	addMoreFiles $2 $3 $4
elif [[ "$1" == "-cr" ]]; then #Create repository
	createRepository $2
elif [[ "$1" == "-es" ]]; then
	extract_source $2 $3
elif [[ "$1" == "-sp" ]]; then
	showInfoProcess $2
elif [[ "$1" == "-sf" ]]; then
	showFile $2
elif [[ "$1" == "-kp" ]]; then # Kill other builds in processing
	killBuildProcess
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
		elif [[ "$1" == "-notus" ]]; then
			IS_UpdateSource=
		elif [[ "$1" == "-us" ]]; then #Create repository
			IS_UpdateSource=True
		elif [[ "$1" == "-rf" ]]; then
			shift
			ROOT=`readlink -f $1`
			KM3=$ROOT/${MODEL_NAME}/KM3
			KM=$KM3/KM
			KM_APP=$KM/application
			KM_WORK=${KM}/work
			logFolder=`echo ${KM_WORK}/${MACHINE_TYPE}* | cut -d ' ' -f1`/log
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
	[ $? -ne 0 ] && echo FAILED && exit 0
	[[ "$IS_UpdateSource" == "True" ]] && updateSource
	[[ "$IS_setupEnvBuild" == "True" ]] && setupEnvBuild
	[[ "$IS_BuildServer" == "True" && "$STATUS" == "True" ]] && startBuild
	exit 0
fi

# Added more files to Repository
#while IFS= read -r line ; do echo $line; cp --parents $line ~/work/git/IT5_42_ZeusS_ZX0_SIM/; done < ~/work/list_file

