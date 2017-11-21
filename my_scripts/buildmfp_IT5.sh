#!/bin/bash
# clear
start=`date +%s`
start_time=`date +%F_%H%M%S`
#Default value:
objects=$@
action=act2
# machine_type=zsb2z
# machine_type=zse3
machine_type=mmlk
KM3=/root/work/KM3
KM=$KM3/KM
WORK=/root/work
REPO_2PORTLAN=$WORK/repository/IT6_Dev
BUILD_SOURCE=KM3/KM/application
Build_SOURCE=$WORK/KM3/KM/application
ORIGINAL_SOURCE=$WORK/original_source

FILE_BRANCH=$logFolder/branch.txt
FILE_CHANGES=(	APIC_Setting_MailSendSetting.h NVDC_Setting_MailSendSetting.h
				NVDC_NetworkSetting.cpp stub_APIC_Setting.cpp
				APIC_Setting_common.h NVDC_ClassDefineTbl.h
				NVDC_Setting_CopyScanJobSetting.h)
FILE_NOT_UPDATE=( NVDC_DebugAPI.h NVDC_DebugAPI.cpp )

function Help() {
	echo "              Copy buildmfp.sh to /root/work folder"
	echo "              Usage: ./buildmfp.sh"
	echo "              Ex: ./buildmfp.sh -a mfpact2 (default: act2)"
}

function backupLogs {
	ls $logFolder/*.log >> /dev/null
	if [ $? -ne 0 ]; then
		return
	fi
	prefix=${action}
	if [ -f $FILE_BRANCH ]; then
		local branch=`cat $FILE_BRANCH`
		[[ -n "$branch" ]] && prefix+="_$branch"
	fi
	backupLogFolder=$logFolder/backup_log_${start_time}_${prefix}
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

function refreshFiles {
	echo "Refresh files ..."
	for file in ${FILE_CHANGES[*]}
	do
		fls=`find $KM/* -name  "$file"`
		for fl in ${fls[*]} 
		do
			echo $fl
			touch $fl
		done
	done
}

function extract_file {
	files="$1"
	local search_fd="$2"
	local target_fd="$3"
	local curr_dir=`pwd`
	# echo "$@"
	cd $search_fd
	for file in ${files[*]}
	do
		fls=`find ./* -name  "$file"`
		# echo "$fls"
		for fl in ${fls[*]} 
		do
			dir=$(dirname "${fl}")
			dir=$(echo "$dir" | sed 's/.//')
			target_fl=$target_fd/$dir
			mkdir -p $target_fl
			cp $fl $target_fl
		done
	done
	cd $curr_dir
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

function find_diff {
	local old_source=$WORK/"$1"
	local new_source=$WORK/"$2"
	target=$WORK/diff
	diff_new_dir=$target/new
	diff_old_dir=$target/old
	files=`find $old_source/* -type f -name "*.h" -o  -name "*.cpp"`
}

function extract_source {

	revision_begin=$1
	revision_end=$2
	# Set the latest revision
	source_OPA=
	
	#revision_end=""
	#revision_end="HEAD"
	if [[ -z $revision_end && -z $revision_begin ]]; then
		revision_begin=HEAD
	fi
	
	echo revision_begin=$revision_begin
	echo revision_end=$revision_end
	
	echo "------------------- $revision_begin:$revision_end ------------------------"
	cur_folder=`pwd`
	des_folder=${WORK}"/extract_source/`date +%F`_${revision_begin}_${revision_end}"
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
	mkdir -p $opa_folder

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
		
		mkdir -p $new_folder/$dir_name_file
		if [[ -n $revision_end ]]; then
			git show ${revision_end}:$line > $new_folder/$line
		else
			cp $line $new_folder/$line
		fi
		# cp --parents $REPO_2PORTLAN/$line $new_folder
		# cp --parents $ORIGINAL_SOURCE/KM3/KM/application/$line $old_folder
	done < "$file_diff_name_only"

	# cd $new_folder
	# mkdir -p ./KM3/KM/application/
	# mv .$REPO_2PORTLAN/* ./KM3/KM/application/
	# rm -rf ./root/
	
	# cd $old_folder
	# mkdir -p ./KM3/KM/application/
	# mv .$ORIGINAL_SOURCE/KM3/KM/application/* ./KM3/KM/application/
	# rm -rf ./root/
	cd $cur_folder tree $old_folder tree $new_folder

	echo "------------------------------------------------------------"
	echo ""
}

function copy_source {
	curr_dir=`pwd`
	folder_REPO=~/work/folder_REPO_BUILD/REPO
	folder_BUILD=~/work/folder_REPO_BUILD/BUILD
	fileUpdateSource=~/work/folder_REPO_BUILD/fileUpdateSource.txt
	rm -f $fileUpdateSource
	rm -rf ~/work/folder_REPO_BUILD
	mkdir -p $folder_REPO
	mkdir -p $folder_BUILD
	work=/root/work
	build_source=~/work/KM3/KM/application
	arr_upSource=(mfp divlib)
	cd /root/work/repository/IT6_Dev/KM/application
	for path in ${arr_upSource[*]}
	do
		files=`find $path/* -type f -name "*.h" -o  -name "*.cpp" -o -name "Makefile"`
		for file in ${files[*]}
		do
			file_name=$(basename "${file}")
			file_build_sour=$build_source/$file
			`cmp --silent $file $file_build_sour`
			if [ $? -ne 0 ]; then
				echo $file | tee -a $fileUpdateSource
				dirname_file_build_sour=$(dirname "${file_build_sour}")
				cp $file --parents $folder_REPO
				cp $build_source/$file --parents $folder_BUILD
				fi
		done
	done
	mv $folder_BUILD/$build_source/* $folder_BUILD
	rm -rf $folder_BUILD/root
	# echo "cp -r $folder_OAP/* ~/work/KM3/KM/applicastion/"
	# yes | cp -r $folder_OAP/* ~/work/KM3/KM/application/
	cd $curr_dir
}

function updateSource {
	echo "Updating source..."
	fileUpdateSource=$logFolder/fileUpdateSource.txt
	work=/root/work

	# arr_upSource=(mfp divlib/client/Proxy/system/nvd divlib/client/Proxy/nicfum divlib/server/Stub)
	arr_upSource=(mfp divlib)
	curr_dir=`pwd`
	ops_find='-name "*.h" -o  -name "*.cpp" -o -name Makefile'
	cd $REPO_2PORTLAN
	cd KM/application
	for path in ${arr_upSource[*]}
	do
		files=`find $path/* -type f -name "*.h" -o -name "*.cpp" -o -name "Makefile" -o -name "MediaMapFile*"`
		for file in ${files[*]}
		do
			file_name=$(basename "${file}")
			file_build_sour=$WORK/$BUILD_SOURCE/$file
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

function diff_report {
	local commands="diff --suppress-common-lines -r -u --strip-trailing-cr"
	local work_fld=/root/work
	local old_file=""
	local new_file=""
	local id=""
	while [[ "$1" != "" ]]; do
		case "$1" in
			-id)
				shift
				id=$1
			;;
			-old)
				shift
				old_file="$1"
			;;
			-new)
				shift
				new_file="$1"
			;;
		esac
		shift
	done
	if [[ -z "$id" || -z "$old_file" || -z "$new_file" ]]; then
		return
	fi
	old_file=$(echo "$old_file" | sed "s/\\\/\\//g")
	new_file=$(echo "$new_file" | sed "s/\\\/\\//g")
	fileName=$(basename "$new_file")

	source_old_file=$work_fld/$old_file
	source_new_file=$work_fld/$new_file
	local fld_report=diff_report/$id
	#mkdir -p $fld_report
	
	#dir_old_file=$(dirname "${old_file}")
	dir_new_file=$(dirname "${new_file}")
	dir_old_file=$fld_report/old/$dir_new_file
	dir_new_file=$fld_report/new/$dir_new_file
	#comment
	#mkdir -p $dir_old_file; 
	#mkdir -p $dir_new_file
	#comment
	#cp $source_old_file $dir_old_file
	#cp $source_new_file $dir_new_file
	
	
	cd diff_report
	local diff_file=$id/$id.txt
	#cp $source_new_file $id/
	
	#comment
	#$commands $id/old/* $id/new/* > $diff_file
	$commands $old_file $new_file > $diff_file
}

function startBuild {
	echo "Build starting..."
	curr_dir=`pwd`
	build_log=$logFolder/build-log-$start_time.txt
	# pmake_log=$logFolder/pmake-log.txt
	cd $REPO_2PORTLAN
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo $branch > $FILE_BRANCH
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
			errors=`find $logFolder/*.log | xargs grep "error:"`
			if [[ -n "$errors" ]]; then
				echo "$errors" > $error_log &
				echo "$errors"
				echo
			fi
		fi
		sleep 30
	done
	printf "Total build time ($machine_type): %d:%02d:%02d\n" $hours $minutes $seconds
	cd $curr_dir
	return 0
}

function findByFile {
	local pattern=$1
	local file=$2
	local result=
	result=`grep -ni $pattern $file`
	echo "$result"
}

function findByFolder {
	local pattern=$1
	local folder="$2"
	echo $folder
	echo "find ${folder} -name "*.cpp" -o -name "*.h""
	local listFiles=`find $folder -name "*.cpp" -o -name "*.h"`
	echo $listFiles
	# for file in "$listFiles"
	# do
		# echo $file
	# done
}

function findSipPattern {
	local fileFolder=~/work/FolderList.txt
	local pattern="sip"
	local path=
	while read line
	do
		command="find $KM3/$line -name "*.cpp""
		echo "$command"
		$command
		done < "$fileFolder"
}

IS_UpdatedSource=True
IS_BackupLog=True

if [[ "$1" == "-h" ]]; then
	Help
	exit 0
elif [[ "$1" == "-r" ]]; then
	if [[ -n "${*:2}" ]]; then
		report "$2" "$3"
	# else
		# report "${FILE_CHANGES[*]}"
	fi
	
elif [[ "$1" == "-cs" ]]; then
	copy_source
elif [[ "$1" == "-us" ]]; then
	updateSource
elif [[ "$1" == "-es" ]]; then
	extract_source $2 $3
elif [[ "$1" == "-sip" ]]; then
	findSipPattern 
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
	echo action: $action
	echo machine_type: $machine_type
	export logFolder=$KM/work/$machine_type/log
	# echo objects: $objects
	# removeObjects
	[[ "$IS_UpdatedSource" == "True" ]] && updateSource
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	
	# updateSource
	# refreshFiles
	startBuild
fi

