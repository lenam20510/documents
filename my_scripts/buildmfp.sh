#!/bin/bash
# clear
start=`date +%s`
start_time=`date +%F_%H%M%S`
#Default value:
PARAMS=$@
CURR_DIR=`pwd`
EXTEN_FILES='-name *.h -o -name *.cpp -o -name Makefile -o -name MediaMapFile*'
REPO_PATH_TO_APP=application
# action=act2
# machine_type=zsb2z
# machine_type=zse3
# machine_type=mmlk
# repo_name=${REPO_NAME}
# machine_type=${MACHINE_TYPE}
# [ -n ${REPO_NAME} ] && repo_name=${REPO_NAME}
# [ -n ${MACHINE_TYPE} ] && machine_type=${MACHINE_TYPE}

function Help() {
	echo "     Copy buildmfp.sh to /root/work folder"
	echo "        Usage:"
	echo "              1) ./buildmfp.sh -us"
	echo "               	Update source code from repository [${REPO_PATH}] to [${BUILD_SOURCE}]"
	echo "              2) ./buildmfp.sh -es [First commit] [End commit]"
	echo "               	Create two new & old folder from repository [${REPO_PATH}]"
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
	prefix=default-${start_time}
	if [ -f $FILE_BRANCH ]; then
		local branch=`cat $FILE_BRANCH`
		[[ -n "$branch" ]] && prefix="$branch"
	fi
	backupLogFolder=$logFolder/backup_log-${prefix}
	mkdir -p $backupLogFolder
	echo "Moving all logs to $backupLogFolder"
	mv $logFolder/*.log $backupLogFolder
	mv $logFolder/*.txt $backupLogFolder
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
}

function strip {
    local STRING=${1#$"$2"}
    echo "${STRING%$"$2"}"
}

function Create_UT {
	echo "Creating UT Spec... "
	analysis_Revision all
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo
	fld_UT=$WORK/UT_Spec; mkdir -p $fld_UT
	file_diff=$fld_UT/${branch}_${revision_begin}_${revision_end}.patch; echo >$file_diff
	file_UT=$fld_UT/${branch}_${revision_begin}_${revision_end}.txt; rm -f $file_UT
	git diff $revision_begin $revision_end > $file_diff
	file_diff_tmp=/tmp/UT_Spec_tmp.txt; touch $file_diff_tmp
	yes | cp $file_diff $file_diff_tmp
	
	local all_diff_func=`cat $file_diff_tmp`
	all_diff_func=$(echo "$all_diff_func" | grep -a -e diff -e ^[\@\@].*[\@\@] -e "::" \
											| grep -a -v ".swp" \
											| grep -a -v "Binary files" \
											| grep -a -v ^'\-' \
											| grep -a -v "\/\/" \
											| grep -a -v ^[^\@].*[\;]) #^[^@].*[;]$
	echo "$all_diff_func" > $file_diff_tmp
	sed -i 's/\r//g'  ${file_diff_tmp} # remove CR
	# file_diff_tmp=~/work/tmp.txt
	info_func=
	file=
	while IFS= read -r line 
	do
		[[ "$line" == *.swp ||  "$line" == *.bak ]] && continue
		if [[ "$line" == "diff"* ]]; then
			if [[ -n "$info_func" ]]; then
				echo $info_func"	$file" | tee -a $file_UT
				# printf '%s%s' $info_func $file | tee -a $file_UT
				info_func=
			fi
			file=`echo "$line" | awk '{print $NF}' `
			file=${file#"b/"*}
			# file=${file#"application"*}
			echo
			echo "<-------------------------------------------------------------------------------------->"
		elif [[ "$line" == "@@"* ]]; then
			if [[ -n "$info_func" ]]; then
				echo $info_func"	$file" | tee -a $file_UT

			fi
			info_func=`printf '%s' "${line}" | awk '{for(i=5;i<=NF;++i) print $i}' ` #Don't xargs here
		else
			echo $line"	$file" | tee -a $file_UT
			info_func=
		fi 
	done < $file_diff_tmp
	if [[ -n "$info_func" ]]; then
		echo $info_func"	$file" | tee -a $file_UT
	fi
	sed -i '$!N; /^\(.*\)\n\1$/!P; D'  ${file_UT} # remove duplicates
	# sed -i 's/\r//g'  ${file_UT} # remove CR
	sed -i 's/\//\\/g' ${file_UT} # changing '//' to '\\'
	sed -i "s/${REPO_PATH_TO_APP}//g" ${file_UT} # remove path to application
	echo 
	echo branch:$branch
	echo '\\'${SIM_IPaddress}${file_diff} | sed  -e 's/\//\\/g'
	echo '\\'${SIM_IPaddress}${file_UT} | sed  -e 's/\//\\/g'
	# tr -d "\n\r" < ${file_UT}
	cd $CURR_DIR
	# rm -f $file_diff_tmp
}

function extract_source {

	analysis_Revision $1 $2
	
	echo "------------------- $revision_begin:$revision_end ------------------------"
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
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
	cd ${REPO_PATH}
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
		# cp --parents ${REPO_PATH}/$line $new_folder
		# cp --parents $ORIGINAL_SOURCE/KM3/KM/application/$line $old_folder
	done < "$file_diff_name_only"
	# Create_UT $file_diff
	# tree $old_folder
	# tree $new_folder
	# Show tree new_folder
	echo
	echo '\\'${SIM_IPaddress}${des_folder} | sed  -e 's/\//\\/g'
	cd ${des_folder}
	find ./new | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
	addedLine=`diff -r old new | grep "> " | wc -l`
	echo "Modified line number: ${addedLine}"
	rm -f ${file_diff_name_only}; rm -f ${file_diff}

	cd $CURR_DIR
	echo "-----------------------------------------------------"
}

function updateSource {
	echo "-->Updating source..."
	local fileUpdateSource=${logFolder}/fileUpdateSource-${start_time}.txt

	# arr_upSource=(mfp divlib/client/Proxy divlib/server)
	arr_upSource=(mfp divlib/client/Proxy/system/ divlib/server/Stub)
	# arr_upSource=(mfp divlib)
	ops_find='-name "*.h" -o  -name "*.cpp" -o -name Makefile'
	touch ${fileUpdateSource}
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
		files=`find $path/* -type f ${EXTEN_FILES}`
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
	cd $CURR_DIR
}

function compareFolder {
	local first_fld=`readlink -f ${1}`
	local second_fld=`readlink -f ${2}`
	first_fld_name=`echo $first_fld | sed  -e 's/\///g'`
	second_fld_name=`echo $second_fld | sed  -e 's/\///g'`
	local cmpFld=${WORK}/compareFolder/${first_fld_name}-${second_fld_name}-${start_time}
	local cmpFld_first=${cmpFld}/${first_fld_name}
	local cmpFld_second=${cmpFld}/${second_fld_name}
	mkdir -p ${cmpFld_first}; mkdir -p ${cmpFld_second}
	local fileUpdateSource=${cmpFld}/fileUpdateSource-${start_time}.txt
	
	# diff all files
	`diff --brief --recursive --no-dereference --new-file --no-ignore-file-name-case ${first_fld} ${second_fld} > ${fileUpdateSource}`
	echo "*********************************different************************************" | tee -a ${fileUpdateSource}
	cd ${first_fld}
	files=`find * -type f ${EXTEN_FILES}`
	for file in ${files[*]}
	do
		file_2nd=${second_fld}/$file
		`cmp --silent $file $file_2nd`
		if [ $? -ne 0 ]; then
			echo $file $file_2nd | tee -a $fileUpdateSource
			cp --parents ${file} ${cmpFld_first}
			cp --parents ${file_2nd} ${cmpFld_second}
		fi
	done
	mv ${cmpFld_second}/${second_fld}/* ${cmpFld_second}
	rm -r ${cmpFld_second}/$(echo "$second_fld" | cut -d "/" -f2)
}

function startBuild {
	echo "-->Build starting..."
	build_log=$logFolder/build-log-$start_time.txt
	error_log=$logFolder/errors.txt
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo ${start_time}-${branch}-${MACHINE_TYPE}-${ACTION} > $FILE_BRANCH
	cd $CURR_DIR
	#start build
	cd $KM/pmake
	echo "./pmake.sh $MACHINE_TYPE ${ACTION} ${QT_VERSION} e s n 4"
	$(./pmake.sh $MACHINE_TYPE ${ACTION} ${QT_VERSION} e s n 4 | tee -a $build_log) &
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
				echo "`grep -n -B5 -A5 --color=always "error:" ${build_log}`" > $error_log &
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

# $1: source folder
# $2: destination folder
# $3: list file
function addMoreFiles {
	local source="$1"
	local destination="$2"
	local file="$3"
	[[ -z $source || -z $destination ||  -z $file ]] && echo "Failed" && return
	cd $source
	while IFS= read -r line
	do
		if [[ -n "$line" ]]; then
			echo "$line ${destination}/$line"
			cp --parents $line ${destination}/
		fi
	done < $file
	cd $CURR_DIR
}

function startMFP {
	local log_fld=~/work/startMFP
	mkdir -p ${log_fld}
	mkdir -p ${log_fld}/old
	mv ${log_fld}/*.txt ${log_fld}/old
	local log_file=${log_fld}/log_start-mfp_${start_time}.txt
	
	export MYALIASE=F ; source ~/.bashrc
	cd /root
	./start-mfp.sh | tee -a ${log_file}
	
	# export MYALIASE=TRUE ; source ~/.bashrc
	# cd ${curr_fld}
	return
}

IS_UpdatedSource=True
IS_BackupLog=True
IS_Build=True
##Getting
#MACHINE_TYPE
# result=`ls ${KM_WORK} -l | grep ^d | head -1 | awk '{print $NF}'`
# echo Machine Type: $result

if [[ "$1" == "-h" ]]; then
	Help
	exit 0
elif [[ "$1" == "-bl" ]]; then
	backupLogs
elif [[ "$1" == "-us" ]]; then
	updateSource
elif [[ "$1" == "-ut" ]]; then
	Create_UT
elif [[ "$1" == "-es" ]]; then
	extract_source $2 $3
elif [[ "$1" == "-amf" ]]; then #Added more files
	addMoreFiles $2 $3 $4
elif [[ "$1" == "-cmp" ]]; then
	[[ -z $2 || -z $3 ]] && exit 
	compareFolder $2 $3 $4
elif [[ "$1" == "-smfp" ]]; then
	startMFP
else #Start build
	while [[ -n "$1" ]]; do
		if [[ "$1" == "-a" ]]; then
			shift
			export ACTION=$1
		elif [[ "$1" == "-m" ]]; then
			shift
			export MACHINE_TYPE=$1
			export logFolder=$KM/work/$MACHINE_TYPE/log
		elif [[ "$1" == "-notus" ]]; then
			IS_UpdatedSource=
		elif [[ "$1" == "-notbl" ]]; then
			IS_BackupLog=
		fi	
		shift
	done	
	FILE_BRANCH=$logFolder/info_start_build.txt
	echo action: $ACTION
	echo machine_type: $MACHINE_TYPE
	echo 
	# checking buildmfp.sh was existed or not
	check=`ps -ef | grep buildmfp.sh | grep -v grep`
	[ $? -ne 0 ] && exit 0
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	[[ "$IS_UpdatedSource" == "True" ]] && updateSource
	[[ "$IS_Build" == "True" ]] && startBuild
	exit 0
fi

# Added more files to Repository
#while IFS= read -r line ; do echo $line; cp --parents $line ~/work/git/IT5_42_ZeusS_ZX0_SIM/; done < ~/work/list_file

