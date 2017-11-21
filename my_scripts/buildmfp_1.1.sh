#!/bin/bash
# clear
start=`date +%s`
start_time=`date +%F_%H%M%S`
#Default value:
objects=$@
action=act2
# machine_type=zsb2z
# machine_type=zse3
# machine_type=mmlk
machine_type=a64_mv7040
WORK=/root/work
KM3=$WORK/KM3
KM=$KM3/KM
REPO_2PORTLAN=$WORK/repository/IT6_Dev
BUILD_SOURCE=$WORK/KM3/KM/application
ORIGINAL_SOURCE=$WORK/original_source
MASTER_BRANCH=master
SIM_IPaddress='192.168.56.102'
export logFolder=$KM/work/$machine_type/log


FILE_CHANGES=(	APIC_Setting_MailSendSetting.h NVDC_Setting_MailSendSetting.h
				NVDC_NetworkSetting.cpp stub_APIC_Setting.cpp
				APIC_Setting_common.h NVDC_ClassDefineTbl.h
				NVDC_Setting_CopyScanJobSetting.h)
FILE_NOT_UPDATE=( NVDC_DebugAPI.h NVDC_DebugAPI.cpp )

function Help() {
	echo "     Copy buildmfp.sh to /root/work folder"
	echo "        Usage:"
	echo "              1) ./buildmfp.sh -us"
	echo "               	Update source code from repository [${REPO_2PORTLAN}] to [${BUILD_SOURCE}]"
	echo "              2) ./buildmfp.sh -es [First commit] [End commit]"
	echo "               	Create two new & old folder from repository [${REPO_2PORTLAN}]"
	echo "              3) ./buildmfp.sh [Option]"
	echo "              [Option] :"
	echo "                      -a      :   action build (act2, divact2, mfpact2, ...). default: act2"
	echo "                      -m      :   machine type (zse3, mmlk, a64_mv7040, ...). default: a64_mv7040"
	echo "                      -notus  :   Do not update source code from repository.  default: Yes"
	echo "                      -notbl  :   Do not backup log.                          default: Yes"
	echo "              Ex: ./buildmfp.sh -a mfpact2 -m a64_mv7040 -notus"
}

function backupLogs {
	echo "-->BackupLogs..."
	ls $logFolder/*.log >> /dev/null
	if [ $? -ne 0 ]; then
		return
	fi
	prefix=default
	if [ -f $FILE_BRANCH ]; then
		local branch=`cat $FILE_BRANCH`
		[[ -n "$branch" ]] && prefix="$branch"
	fi
	backupLogFolder=$logFolder/backup_log-${start_time}-${prefix}
	mkdir -p $backupLogFolder
	echo "Moving all logs to $backupLogFolder"
	mv $logFolder/*.log $backupLogFolder
	mv $logFolder/*.txt $backupLogFolder
}

function removeObjects {
	echo "Removing objects: $objects ..."
	for ob_find in ${objects[*]}
	do
		obs=`find $KM/* -name  "$ob_find.o"`
		for ob in ${obs[*]} 
		do
			echo $ob
			rm -f $ob
		done
	done
} 

function report {
	# parameters=$@
	listFile=$WORK/filelist.txt
	target=$WORK/report
	if [[ -n "$@" ]]; then
		old_source=$WORK/$1
		repo_source=$WORK/$2
	else
		old_source=$WORK/original_source/KM3/KM/application
		repo_source=$WORK/repository/2PortLan
	fi
	rm -rf $WORK/report/*
	report_new_dir=$target/new
	report_old_dir=$target/old
	mkdir -p $report_new_dir
	mkdir -p $report_old_dir
	curr_dir=`pwd`
	for file in `cat $listFile`
	do
		cd $repo_source
		cp $file --parents $report_new_dir/
		cd $old_source
		cp $file --parents $report_old_dir/
	done
	cd $curr_dir
}

function extract_source {

	revision_begin=$1
	revision_end=$2
	# Set the latest revision
	source_OPA=
	cur_folder=`pwd`
	cd $REPO_2PORTLAN
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
			previous_commit=$(echo ${rev_list_branch} | cut -c$((${#rev_list_master_branch}+1))- | awk '{print $2;}')
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
	
	echo "------------------- $revision_begin:$revision_end ------------------------"
	cd $cur_folder
	des_folder=${WORK}"/extract_source/`date +%F_%H%M%S`_${branch}_${revision_begin}_${revision_end}"
	mkdir -p $des_folder
	rm -rf $des_folder/*
	file_diff_name_only=$des_folder/file_diff_name_only.txt
	file_diff=$des_folder/diff_${revision_begin}_${revision_end}.patch
	old_folder=$des_folder/old
	new_folder=$des_folder/new
	opa_folder=$des_folder/opa
	# Cleanup & create destination folder.
	mkdir -p $old_folder
	mkdir -p $new_folder
	#cp opa
	# mkdir -p $opa_folder

	# This is one-line command to get list file from "revision_begin" to "revision_end".
	# And, perform copying changed files to new location by keep folder structure same as source file.
	# git diff 06a3af6 8174c67 --name-only
	cd $REPO_2PORTLAN
	git diff $revision_begin $revision_end > $file_diff
	git diff $revision_begin $revision_end --name-only > $file_diff_name_only
	# git diff $revision_begin $revision_end --name-only | 
	while read line
	do
		dir_name_file=$(dirname "${line}")
		mkdir -p $old_folder/$dir_name_file
		git show ${revision_begin}:$line > $old_folder/$line
		if [ $? -ne 0 ]; then # If having a error, we will find first commit of this file.
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
		# cp --parents $REPO_2PORTLAN/$line $new_folder
		# cp --parents $ORIGINAL_SOURCE/KM3/KM/application/$line $old_folder
	done < "$file_diff_name_only"

	# tree $old_folder
	# tree $new_folder
	# Show tree new_folder
	echo
	echo '\\'${SIM_IPaddress}${des_folder} | sed  -e 's/\//\\/g'
	cd ${des_folder}
	find ./new | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"

	cd $cur_folder
	echo "-----------------------------------------------------"
}

function updateSource {
	echo "-->Updating source..."
	local fileUpdateSource=${logFolder}/fileUpdateSource-${start_time}.txt
	work=/root/work

	# arr_upSource=(mfp divlib/client/Proxy divlib/server)
	arr_upSource=(mfp divlib/client/Proxy/system/ divlib/client/Proxy/nicfum divlib/server/Stub)
	# arr_upSource=(mfp divlib)
	curr_dir=`pwd`
	ops_find='-name "*.h" -o  -name "*.cpp" -o -name Makefile'
	touch ${fileUpdateSource}
	echo fileUpdateSource:$fileUpdateSource
	cd $REPO_2PORTLAN
	
	subflds=`ls . -1 | grep -vE "/usr|^$"`
	if [[ "$subflds" == *"KM"* ]]; then
		cd KM/application
	elif [[ "$subflds" == *"application"* ]]; then
		cd application
	fi
	
	for path in ${arr_upSource[*]}
	do
		files=`find $path/* -type f -name "*.h" -o -name "*.cpp" -o -name "Makefile" -o -name "MediaMapFile*"`
		for file in ${files[*]}
		do
			file_name=$(basename "${file}")
			file_build_sour=$BUILD_SOURCE/$file
			`cmp --silent $file $file_build_sour`
			if [ $? -ne 0 ]; then
				echo $file $file_build_sour | tee -a $fileUpdateSource
				dirname_file_build_sour=$(dirname "${file_build_sour}")
				mkdir -p $dirname_file_build_sour
				yes | cp -f $file $file_build_sour
				touch $file_build_sour
			fi
		done
	done
	cd $curr_dir
}

function startBuild {
	echo "Build starting..."
	curr_dir=`pwd`
	build_log=$logFolder/build-log-$start_time.txt
	# pmake_log=$logFolder/pmake-log.txt
	cd $REPO_2PORTLAN
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo ${branch}-${machine_type}-${action} > $FILE_BRANCH
	cd $curr_dir
	#start build
	echo $KM/pmake
	cd $KM/pmake
	echo "./pmake.sh $machine_type $action q530 e s n 4"
	$(./pmake.sh $machine_type $action q530 e s n 4 | tee -a $build_log) &
	sleep 5
	loop=true
	error_log=$logFolder/errors.txt
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
			errors=`egrep -in --color=always -e "error:" -e " error " ${build_log}`
			if [[ -n "$errors" ]]; then
				echo "$errors"
				echo "$errors" > $error_log &
				echo
			fi
		fi
		sleep 30
	done
	printf "Total build time ($machine_type): %d:%02d:%02d\n" $hours $minutes $seconds
	cd $curr_dir
	return 0
}

function startMFP {
	cd ~
	log_MFP=~/work/startMFP
	mkdir -p $log_MFP
	./start-mfp.sh | tee -a $log_MFP/log_start-mfp_${start_time}.txt
	return
}

IS_UpdatedSource=True
IS_BackupLog=True
IS_Build=True

if [[ "$1" == "-h" ]]; then
	Help
	exit 0
elif [[ "$1" == "-r" ]]; then
	if [[ -n "${*:2}" ]]; then
		report "$2" "$3"
	# else
		# report "${FILE_CHANGES[*]}"
	fi
	
elif [[ "$1" == "-us" ]]; then
	updateSource
elif [[ "$1" == "-es" ]]; then
	extract_source $2 $3
# elif [[ "$1" == "-sip" ]]; then
	# findSipPattern
# elif [[ "$1" == "-smfp" ]]; then
	# startMFP 	
else #Start build
	while [[ -n "$1" ]]; do
		if [[ "$1" == "-a" ]]; then
			shift
			action=$1
		elif [[ "$1" == "-m" ]]; then
			shift
			machine_type=$1
		elif [[ "$1" == "-notus" ]]; then
			IS_UpdatedSource=
		elif [[ "$1" == "-notbl" ]]; then
			IS_BackupLog=
		fi	
		shift
	done	
	export logFolder=$KM/work/$machine_type/log
	FILE_BRANCH=$logFolder/branch.txt
	echo action: $action
	echo machine_type: $machine_type
	echo 
	
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	[[ "$IS_UpdatedSource" == "True" ]] && updateSource
	[[ "$IS_Build" == "True" ]] && startBuild
	Exit 0
fi

