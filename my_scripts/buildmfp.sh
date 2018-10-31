#!/bin/bash
# clear
# PPID=$$
# echo PPID:$PPID
start=`date +%s`
start_time=`date +%F_%H%M%S`
#Default value:
BASENAME=`basename "$0"`
BASEDIR=`dirname $(readlink -f "$0")`
PARAMS=$@
CURR_DIR=`pwd`
EXTEN_FILES='-name *.h -o -name *.cpp -o -name Makefile -o -name MediaMapFile* -o -name *.txt'
REPO_PATH_TO_APP=application
FileInCommonAPI=${WORK}/listFileInCommonAPI.txt
# action=act2
# machine_type=zsb2z
# machine_type=zse3
# machine_type=mmlk
# repo_name=${REPO_NAME}
# machine_type=${MACHINE_TYPE}
# [ -n ${REPO_NAME} ] && repo_name=${REPO_NAME}
# [ -n ${MACHINE_TYPE} ] && machine_type=${MACHINE_TYPE}
COUNT_TRAP=0
PID_PMAKE=
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
		getLengthTime
		printf "*************************%d:%02d:%02d*****************************\n" $hours $minutes $seconds
		# echo "${nameProcess} is being used. Please wait..."
		echo "$pid" | awk '{print $2,$3,$7,$8,$9,$(NF-1),$NF}'
		# echo "$pid" | grep --color=auto $nameProcess | awk '{print $2,$3,$7,$(NF-1),$NF}'
		sleep 3
	done
	# echo "$pid" | awk '{print $2,$3,$7,$(NF-1),$NF}'
	# echo "Safe kill process!!"
	killHardProcess
}
# trap killHardProcess SIGINT
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

function Help() {
	echo "     Copy buildmfp.sh to /root/work folder"
	echo "        Usage:"
	echo "              1) ./buildmfp.sh -us"
	echo "               	Update source code from repository [${REPO_PATH}] to [${KM_APP}]"
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

SUFFIX="e r n 4"

getLengthTime() {
	curr=`date +%s`
	let deltatime=curr-start
	let hours=deltatime/3600
	let minutes=(deltatime/60)%60
	let seconds=deltatime%60
}

function backupLogs {
	[[ "$IS_MakeFilesMFP" == "True" ]] && return
	echo "-->BackupLogs..."
	ls $logFolder/*.log >> /dev/null
	if [ $? -ne 0 ]; then
		return
	fi
	mkdir -p ${logFolder}/old; mv ${logFolder}/'backup_log-'* ${logFolder}/old >/dev/null # Moving other backup-logs to old folder.
	prefix=default-${start_time}
	if [[ -f $FILE_BRANCH ]]; then
		local branch=`cat $FILE_BRANCH`
		[[ -n "$branch" ]] && prefix="$branch"
	fi
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

function rmComment {
	input=$1
	output_comment=
	input_tmp=/tmp/tmp_rmComment_input_$start_time.txt
	echo "$input" > $input_tmp
	output_tmp=/tmp/tmp_rmComment_output_$start_time.txt; echo >$output_tmp
	# output=${input%%\/\/*}; echo "$output"
	while IFS= read -r line
	do
		[[ -z  $line ]] && continue
		output=${line%%\/\/*}; echo $output >> $output_tmp
	done < $input_tmp
	sed -i '/^\s*$/d' $output_tmp #remove empty line
	output_comment=`cat $output_tmp`
	# rm -f $input_tmp $output_tmp
}

function reverString {
	input="$1"
	reverse=""
	len=${#input}
	for (( i=$len-1; i>=0; i-- ))
	do 
		reverse="$reverse${input:$i:1}"
	done
	echo "$reverse"
}

function getFunNameAtLine {
	local fileName=$1
	local lineNumber=$2
	local contents=$3 # No need
	local ret=
	[[ ! -f $fileName || -z $lineNumber ]] && return
	# if [[ "$contents" == $"void"* || "$contents" == $"int"* ]] \
		# || [[ "$contents" == *"::"* && "$contents" != *"newInstance"* && "$contents" == *"("* ]]
		# ;then
		# echo "$contents" | cut -d '(' -f1 | awk '{print $NF}'
	# else
		# checkNumber $lineNumber
		# [ $? -ne 0 ] && return
		content=`sed -n 1,${lineNumber}p < ${fileName}`
		content=`echo "$content" | grep -na -e ^'{' -e ^'}' `
		check=`echo "$content" | tail -n1`
		if [[ -z $check || "$check" == *"}"* ]]; then
			ret="<global>"
		else
			lineStartFunc=`echo $check | cut -d ':' -f1` # Get number
			checkNumber $lineStartFunc
			[ $? -ne 0 ] && return
			ret=`sed -n $((${lineStartFunc}-1))p < ${fileName}`
			ret=${ret%%\/\/*}
			# echo ret:$ret
			if [[ "$ret" != *"("* && "$ret" != $"class"* && "$ret" != $"struct"* ]]; then
				file_tmp=/tmp/tmp_getFunNameAtLine
				getStart=`sed -n 1,$((${lineStartFunc}-1))p < ${fileName} | grep -a '('`
				echo "$getStart" | tail -n20 > $file_tmp
				tac $file_tmp > ${file_tmp}_out
				while IFS= read -r line
				do
					ret=${line%%\/\/*}
					# echo ret:$ret
					[[ "$ret" == *'('* ]] && break
				done < ${file_tmp}_out
			fi
			# if [[ "$ret" != *"("* && "$ret" != $"class"* && "$ret" != $"struct"* ]]; then
				# ret=`sed -n 1,$((${lineStartFunc}-1))p < ${fileName}`
				# ret=`echo "$ret" | grep -na '(' | tail -n1`
			# fi
		fi
		case ${ret} in
			'<global>') echo $ret;;
			"class"*|"struct"*) echo $ret | awk '{print $2}';;
			*"("* )	echo "$ret" | cut -d '(' -f1 | awk '{print $NF}';;
			*)
				echo "$ret" | awk '{print $NF}';;
		esac
	# fi
}

function checkNumber {
	case $1 in
    ''|*[!0-9]*) return 1 ;; #echo bad 
    *) return 0 ;; #echo good
	esac
}

function addDebugComt {
	file_name=$1
	content="$2"
	cd $REPO_PATH
	if [[ ! -f $file_name || -z $content ]]; then
		echo Parameter input error. FAILED!!!
	else
		line_num=`echo $content | cut -d ',' -f1 | cut -d '-' -f2`
		func_name=`echo $content | cut -d '(' -f1 | awk '{print $NF}'`
		grep "${func_name}:${file_name}" $file_addDebug
		[ $? -eq 0 ] && echo "Already existed" && return
		getContent=`sed -n 1,${line_num}p < ${file_name} | grep -an -A5 ${func_name} | tail -n7 | grep -a '{' | head -n1`
		index=`echo $getContent | cut -d '-' -f1`
		[[ $(checkNumber $line_num) -ne 0 ]] && echo FAILDDDDDDDDDDDDDDDDDDDDDDDDDD && return
		let index=$((index + 1))
		echo "Adding a debug comment at $file_name:$index"
		sed -i ${index}i'printf("addDebugComment %s_%s_%d\\n", __FILE__, __LINE__, __FUNCTION__);' $file_name
		[ $? -ne 0 ] && echo Added FAILDDDDDDDDDDDDDDDDDDDDDDDDDD
		unix2dos $file_name
		echo "${func_name}:${file_name}" >> $file_addDebug
	fi
	cd $CURR_DIR
}

function Create_UT {
	echo "Creating UT Spec... "
	analysis_Revision all
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo
	is_addDebug=$@
	echo is_addDebug:$is_addDebug
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
	line_num=
	prefix=UT_001
	prefix_num=1
	export file_addDebug=${WORK}/create_UT_AddDebug.txt; echo >$file_addDebug
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
			# echo "<------>${file}<------>" | tee -a $file_UT
		elif [[ "$line" == "@@"* ]]; then
			# if [[ -n "$info_func" ]]; then
				# echo $info_func"	$file" | tee -a $file_UT

			# fi
			info_func=`printf '%s' "${line}" | awk '{for(i=5;i<=NF;++i) print $i}' ` #Don't xargs here
			
			echo $info_func"	$file" | tee -a $file_UT
			info_func=
			# [[ -n $is_addDebug ]] && addDebugComt $file "${line}"
		else
			# echo $line"	$file" | tee -a $file_UT
			echo "--------------->"$line
		fi 
	done < $file_diff_tmp
	if [[ -n "$info_func" ]]; then
		echo $info_func"	$file" | tee -a $file_UT
		# [[ -n $is_addDebug ]] && addDebugComt $file "${line}"
	fi
	# rm -f $file_addDebug
	sed -i '$!N; /^\(.*\)\n\1$/!P; D'  ${file_UT} # remove duplicates
	# sed -i 's/\r//g'  ${file_UT} # remove CR
	sed -i "s/${REPO_PATH_TO_APP}//g" ${file_UT} # remove path to application
	sed -i 's/\//\\/g' ${file_UT} # changing '//' to '\\'
	echo 
	echo branch:$branch
	showFile $file_diff
	showFile $file_UT
	# tr -d "\n\r" < ${file_UT}
	cd $CURR_DIR
	# rm -f $file_diff_tmp
}

function extract_source {
	revision_begin=${1:-all}
	revision_end=$2
	[ ! -d $REPO_PATH ] && echo "Repository is not exist!!!" && return
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`; [[ -z $branch ]] && branch=default
	des_folder=${MY_WORK}"/extract_source/${REPO_NAME}/${branch}"; mkdir -p $des_folder
	file_FirstCommit=$des_folder/file_FirstCommit.txt
	first_commit=`cat $file_FirstCommit`
	if [[ $revision_begin == all ]]; then
		if [[ -n $first_commit ]]; then
			echo OK
			revision_begin=$first_commit
			revision_end=
		else
			analysis_Revision $revision_begin $revision_end
			echo $revision_begin > $file_FirstCommit
		fi
	else
		analysis_Revision $revision_begin $revision_end
	fi
	
	echo "------------------- $revision_begin:$revision_end ------------------------"
	# des_folder=${WORK}"/extract_source/`date +%F_%H%M%S`_${branch}_${revision_begin}_${revision_end}"
	# mv ${des_folder}-{,.}* ${des_folder} # Moving old extract-sources to backup folder.
	# des_folder=${des_folder}"/${branch}-${revision_begin}-${revision_end}-`date +%F_%H%M%S`"
	des_folder=${des_folder}"/${revision_begin}-${revision_end}-`date +%F_%H`"
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
	# changedLine+=" => Actual Changed: "`git diff -w $revision_begin HEAD | grep -c -E "(^[+-]\s*(\/)?\*)|(^[+-]\s*\/\/)"`
	actualChanged=`git diff -w $revision_begin HEAD \
		| egrep -E "(^[+])" | grep -v -E "(^[+]\s*\/\/)" | grep -v -E "(^[+]\/\*)" | grep -v -E "(^[+]\*\/)"\
		| grep -v -E "(^[+]\+\+)"`
	changedLine+=" => Actual Changed: "`echo "$actualChanged" | grep '[^ ]' | wc -l`
	echo "$actualChanged" > $des_folder/actualChanged.txt
	cd ${des_folder}
	find ./new | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
	# find . -maxdepth 2 | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/" # list directories
	# rm -f ${file_diff_name_only}; rm -f ${file_diff}
	echo "${changedLine}"
	showFile ${des_folder}

	cd $CURR_DIR
	echo "-----------------------------------------------------"
}

function updateSource {
	echo "-->Updating source..."
	local fileUpdateSource=${logFolder}/fileUpdateSource-`date +%F`.txt
	[ ! -d $REPO_PATH ] && echo "Repository is not exist!!!" && return

	arr_upSource=(mfp divlib/client/Proxy/system divlib/server/Stub divlib/Tool)
	# arr_upSource=(mfp divlib/client/Proxy/system/ divlib/server/Stub)
	# arr_upSource=(mfp divlib)
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
	
	[[ "$IS_MakeFilesMFP" == "True" ]] && echo >$listMakeFilesRepo
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

				[[ "$IS_MakeFilesMFP" == "True" ]] && echo $file_build_sour >> $listMakeFilesRepo
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

function startBuild {
	echo "-->Build starting..."
	build_log=$logFolder/build-log-`date +%F`.txt
	error_log=$logFolder/errors.txt
	cd ${REPO_PATH}
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo ${start_time}-${branch}-${MACHINE_TYPE}-${ACTION} > $FILE_BRANCH
	cd $CURR_DIR
	#start build
	cd $KM/pmake
	echo "./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} e s n 4"
	$(./${PMAKE_FILE} $MACHINE_TYPE ${ACTION} ${QT_VERSION} e s n 4 | tee -a $build_log) &
	PID_PMAKE=`echo $!`
	echo PID_PMAKE:$PID_PMAKE
	sleep 5
	loop=true
	while [[ -n "$loop" ]]; do
		# id=`ps -ef | grep -v "grep" | grep ./pmake.sh`
		`ps -ef | grep -v grep | grep -q $PID_PMAKE`
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
			errors=`egrep -in --color=always -e "error:" -e " error " -e " error$" -e "^error " ${build_log}`
			echo "$errors"
			if [[ -n "$errors" && "$errors" == *"error:"* ]]; then
				# echo "`grep -n -B5 -A5 --color=always "error:" ${build_log}`" > $error_log &
				echo "`grep -n --color=always "error:" ${build_log}`" > $error_log &
			fi
			echo
		fi
		sleep 30
	done
	printf "Total build time ($MACHINE_TYPE): %d:%02d:%02d\n" $hours $minutes $seconds
	egrep -in --color=always -e "error:" -e " error " -e " error$" -e "^error " ${build_log}
	cd $CURR_DIR
	exit 0
}

# $1: source folder
# $2: destination folder
# $3: list file
function addMoreFiles {
	echo "-->addMoreFiles..."
	local source=`readlink -f $1`
	local destination=`readlink -f $2`
	local file=`readlink -f $3`
	[[ ! -d $source || ! -d $destination || ! -f $file ]] && echo "Failed" && return
	echo >> $file
	cd $source
	while IFS= read -r line
	do
		if [[ -n "$line" ]]; then
			if [ -f $line ]; then
				file_build_sour=${destination}/$line
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

# -all		:	search in application				deafaut:In CommonAPI
# -sall		:	Show Function Name, Number line	default: No
# -sf		:	Show Function Name				default: No
# -sn		:	Show number line				default: No
# -sc		:	Show in CommonAPI				default: No
# -f		: 	Find NameFile in CommonAPI or Not	default: No
function findInCommonAPI {
	echo $@
	pattern=
	is_file=
	is_all=
	is_ShowFunc=
	is_ShowNumber=
	is_ShowCommon=
	InCommon=
	while [[ -n "$1" ]]; do
		if [[ "$1" == "-all" ]]; then
			is_all=True
		elif [[ "$1" == "-f" ]]; then
			is_file=True
			shift
			pattern=$1
		elif [[ "$1" == "-sf" ]]; then
			is_ShowFunc=True
		elif [[ "$1" == "-sall" ]]; then
			is_ShowFunc=True
			is_ShowNumber=True
			is_ShowCommon=True
		elif [[ "$1" == "-sn" ]]; then
			is_ShowNumber=True
		elif [[ "$1" == "-sc" ]]; then
			is_ShowCommon=True
		else
			pattern=$1
			[[ $pattern == *.h || $pattern == *.cpp || $pattern == *.c ]] && is_file=True
		fi	
		shift
	done
	fileInCommon=`cat ${FileInCommonAPI}`
	file_pattern=${WORK}/list_pattern.txt
	
	if [[ -n $is_file ]]; then # Search file name in CommonAPI
		if [[ "$pattern" != *".txt"  ]]; then
			echo "$fileInCommon" | grep -i --color=auto $pattern
		else
			# Search in a target file.
			while IFS= read -r line
			do
				line=`echo $line | xargs`
				file_name=$(basename "${line}")
				echo "*************************************"
				echo "$fileInCommon" | grep --color=auto $file_name #| tee -a $output_file
			done < $pattern
			# showFile $output_file
		fi
	else
		count=0
		FILENAME=${pattern}-`date +%F`.txt
		OUTPUT=/root/work/findCommonAPI; mkdir -p $OUTPUT
		tmp_file=${OUTPUT}/${pattern}.txt; echo >$tmp_file
		output_file=${OUTPUT}/${FILENAME}; echo >$output_file
		cd ${KM_APP}
		if [[ -n $is_all ]]; then
				grep -rna --include=*.h --include=*.cpp --include=*.c --include=MediaMapFile* --exclude=*.bak --exclude=*.class --exclude=*.o --exclude=*.swp ${pattern} * > $tmp_file
		else
			InCommon=True
			for fld in $fileInCommon
			do
				if [ -f $fld ]; then
					grep -naHi ${pattern} $fld >> $tmp_file
				fi
			done
		fi
		cd $CURR_DIR
		
		if [[ -n $is_ShowFunc || -n $is_ShowNumber || -n $is_ShowCommon ]]; then
			while IFS= read -r line 
			do
				funName=
				result=
				[[ -z $line ]] && continue
				fileName=`echo $line | cut -d ':' -f1`
				lineNumber=`echo $line | cut -d ':' -f2`
				content=`echo $line | cut -d ':' -f3-`
				# ignore if it's a comment.
				echo $content | grep ^"//" > /dev/null
				[[ $? -eq 0 ]] && echo isComment:$content && continue
				if [[ -n ${fileName} && -n ${lineNumber} ]]; then
					funName=$(getFunNameAtLine ${KM_APP}/${fileName} ${lineNumber} "${content}")
					[[ -z "$funName" ]] && funName="<global>"
					if [[ -n $is_ShowCommon ]]; then
						b_IsCommon=o
						if [[ -z $InCommon ]]; then
							echo "$fileInCommon" | grep -i $fileName > /dev/null
							[ $? -ne 0 ] && b_IsCommon=x
						fi
						result="${b_IsCommon}"
					fi
					result+="	${fileName}"
					[[ -n $is_ShowNumber ]] && result+="	${lineNumber}"
					[[ -n $is_ShowFunc ]] && result+="	${funName}"
					result+="	${content}"
					echo "$result" >> $output_file
				else
					echo "FAILDDDDDDDDDDDDDDDDDDDDDDDDDD:$line" >> $output_file
				fi
			done < $tmp_file
		else
			output_file=$tmp_file
		fi
		grep -ai --color=always ${pattern} $output_file #show results into the terminal.
		# cat $output_file
		sed -i 's/\r//g'  ${output_file} # remove CR
		sed -i '/^\s*$/d' $output_file # remove empty line
		# rm -f $tmp_file
		showFile $output_file
		echo Count: `grep -c ${pattern} $output_file `
	fi
	
}

function showFile {
	echo 
	echo '\\'${IPaddress}${1} | sed  -e 's/\//\\/g'
}

function createRepository {
	echo "-->createRepository..."
	cd $WORK
	local fld_source=${1:-${KM}}
	echo fld_source:$fld_source
	[ ! -d $fld_source ] && echo "fld_source is not exist" && return
	local file_listInCommon=`readlink -f ${FILE_REPO}`
	[ ! -f $file_listInCommon ] && echo "file_listInCommon is not exist" && return
	local path_repo=$REPO_PATH
	local path_repo_copy=${path_repo}; mkdir -p $path_repo_copy
	echo path_repo:$path_repo_copy
	addMoreFiles $fld_source $path_repo_copy $file_listInCommon
	echo "initial repository..."
	git init $path_repo
	cd $path_repo
	git add ./*; git commit -m "initial"
	cd $CURR_DIR
}

function startMFP {
	local is_server=$1
	local log_fld=~/work/startMFP
	#check the file exist or not
	[[ ! -f /km/fw/bin/mfp000_allQt || ! -f /km/fw/bin/mfp000_allQt.map ]] && echo "/km/fw/bin/mfp000_allQt* don't exist" && return
	# mkdir -p ${log_fld}
	mkdir -p ${log_fld}/old
	mv ${log_fld}/*.* ${log_fld}/old
	local log_file=${log_fld}/log_start-mfp_${start_time}.txt
	showFile $log_file
	# echo log_file:$log_file
	# export MYALIASE=F ; source ~/.bashrc
	export myaliase=F ; source ~/.bashrc
	cd /root
	./start-mfp.sh $is_server | tee -a ${log_file}
	
	# export MYALIASE=TRUE ; source ~/.bashrc
	cd ${CURR_DIR}
	return
}

function gccCMD {
	local cmd=$1
	# echo $cmd
	$cmd | tee -a $logGCCMake
}

function makeFilesMFP {
	echo "-->makeFilesMFP..."
	local is_client=
	local is_server=
	local is_mfp=
	listFiles=$listMakeFilesMFP
	if [[ "$IS_UpdatedSource" == "True" ]]; then
		listFiles=$listMakeFilesRepo
		[[ -n `cat $listMakeFilesRepo` ]] && cp $listMakeFilesRepo $listMakeFilesMFP
	fi
	local is_Build=
	echo listFiles=$listFiles
	[ ! -f $listFiles ] && echo "$listFiles is not exist" && exit 0
	while IFS= read -r line 
	do
		[[ ! -n $line ]] && continue
		echo "line:$line"
		[[ ! -f $line ]] && echo "error: $line is not exist!!!" && continue
		path_source=
		[[ "$line" == *".h" || "$line" != *".cpp" ]] && continue
		if [[ "$line" == *"application/divlib/client"* ]]; then
			is_client=True
			path_source='application/divlib/client'
		elif [[ "$line" == *"application/divlib/server"* ]]; then
			is_server=True
			path_source='application/divlib/server'
		elif [[ "$line" == *"application/mfp"* ]]; then
			is_mfp=True
			path_source='application/mfp'
		else
			echo "$line don't support!!!"
			continue
		fi
		fileName=$(basename "${line}")
		if [[ "$line" != *".cpp" ]]; then
			echo "$line don't support!!!"
			continue
			# fileNameNotExten=`echo $fileName | cut -d '.' -f1`
			# lineTmp=`find ${KM}/${path_source} -iname ${fileNameNotExten}.cpp | head -n1`
			# [[ ! -n $lineTmp ]] && echo "Can not find .cpp for $line" && continue
			# line=$lineTmp
		fi
		cmdMakeFile=$(grep -rha --include=*.log ${GCC}.*${path_source}.*${fileName} ${logFolder} | head -n1)
		cmdMakeFileFull=${cmdMakeFile% *}" $line"
		if [[ -n $cmdMakeFileFull ]]; then
			is_Build=True
			echo "$cmdMakeFileFull"
			$cmdMakeFileFull 2>&1 $logGCCMake
		else
			echo "error: Can't file path for $fileName"
		fi
	done < $listFiles
	[[ ! -n $is_Build ]] && return 0
	errors=`egrep -in --color=always -e "error:" ${logGCCMake}`
	if [[ -n $errors ]]; then
		echo ============================================
		egrep -in --color=always -e "line:" -e "error:" -e " error " -e " error$" -e "^error " $logGCCMake
		echo ============================================
		return 0
	fi
	if [[ "$is_client" == "True" ]]; then
		cmdMake='Creating libdiv_client.so'
		cmdMakeDivClient=$(grep -rha -A1 --include=*.log "$cmdMake" ${logFolder} | head -n2 | tail -n1 )
		if [[ -n $cmdMakeDivClient && $cmdMakeDivClient == *libdiv_client.so* ]]; then
			echo ${cmdMake}...
			$cmdMakeDivClient 2>&1 $logGCCMake
		else
			echo "error: Can't file path for $cmdMake"
		fi
		echo "cp libdiv_client.so $KM_FW/lib/libdiv_client.so"
		cp libdiv_client.so $KM_FW/lib/libdiv_client.so; rm -f libdiv_client.so
	fi
	if [[ "$is_server" == "True" ]]; then
		cmdMake='Creating libdiv_server.so'
		cmdMakeDivServer=$(grep -rha -A1 --include=*.log "$cmdMake" ${logFolder} | head -n2 | tail -n1 )
		if [[ -n $cmdMakeDivServer && $cmdMakeDivServer == *libdiv_server.so* ]]; then
			echo ${cmdMake}...
			$cmdMakeDivServer 2>&1 $logGCCMake
		else
			echo "error: Can't file path for $cmdMake"
		fi
		echo "cp libdiv_server.so $KM_FW/lib/libdiv_server.so"
		cp libdiv_server.so $KM_FW/lib/libdiv_server.so; rm -f libdiv_server.so
	fi
	if [[ "$is_mfp" == "True" ]]; then
		cmdMake='Creating mfp000_allQt'
		cmdMakeMfp000=$(grep -rha -A1 --include=*.log "$cmdMake" ${logFolder} | head -n2 | tail -n1 )
		if [[ -n $cmdMakeMfp000 && $cmdMakeMfp000 == *mfp000* && $cmdMakeMfp000 == *ljsoncpp ]]; then
			echo ${cmdMake}...
			echo "$cmdMakeMfp000"
			$cmdMakeMfp000 | tee -a $logGCCMake
			if [ ! -f $KM_FW/bin/mfp000_allQt ]; then
				echo "error: Mfp make error"
				return
			fi
			# [ ! -f /km/fw/bin/mfp000_allQt ] && echo "cp to /km/fw/bin/mfp000_allQt" && cp /root/work/KM3/KM/pmake/${MACHINE_TYPE}/all/km/fw/bin/mfp000_allQt /km/fw/bin/mfp000_allQt
		else
			echo "error: Can't file path $cmdMake"
		fi
		cmdMake='Creating mfp000_allQt.map'
		cmdMakeMfp000=$(grep -rha -A1 --include=*.log "$cmdMake" ${logFolder} | head -n2 | tail -n1 )
		if [[ -n $cmdMakeMfp000 && $cmdMakeMfp000 == *mfp000* ]]; then
			echo ${cmdMake}...
			echo "$cmdMakeMfp000"
			cmdMakeMfp000Full=`echo $cmdMakeMfp000 | cut -d '|' -f1`
			cmdCut=`echo $cmdMakeMfp000 | cut -d '|' -f3- | cut -d '>' -f1`
			cmdMap=`echo $cmdMakeMfp000 | cut -d '>' -f2-`
			echo "$cmdMakeMfp000Full | sed -e '/ V /d' -e 's/(.*)//g' -e '/::/d' | $cmdCut > $cmdMap"
			$cmdMakeMfp000Full | sed -e '/ V /d' -e 's/(.*)//g' -e '/::/d' | $cmdCut > $cmdMap
			if [ ! -f $KM_FW/bin/mfp000_allQt.map ]; then
				echo "error: Mfp.map make error"
				return
			fi
			# [ ! -f /km/fw/bin/mfp000_allQt.map ] && echo "cp to /km/fw/bin/mfp000_allQt.map" && cp /root/work/KM3/KM/pmake/${MACHINE_TYPE}/all/km/fw/bin/mfp000_allQt.map /km/fw/bin/mfp000_allQt.map
		else
			echo "error: Can't file path for $cmdMake"
		fi
	fi
	echo ============================================
	egrep -in --color=always -e "line:" -e "error:" -e " error " -e " error$" -e "^error " $logGCCMake
	echo ============================================
	exit 0
}


IS_UpdatedSource=True
IS_BackupLog=True
IS_Build=True
IS_MakeFilesMFP=
IS_MakeFilesDivlib=
FILE_BRANCH=$logFolder/info_start_build.txt
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
	Create_UT $2
elif [[ "$1" == "-es" ]]; then
	extract_source $2 $3
elif [[ "$1" == "-amf" ]]; then #Added more files
	addMoreFiles $2 $3 $4
elif [[ "$1" == "-cmp" ]]; then
	[[ -z $2 || -z $3 ]] && exit 
	compareFolder $2 $3 $4
elif [[ "$1" == "-smfp" ]]; then
	startMFP $2
elif [[ "$1" == "-gf" ]]; then
	getFunNameAtLine $2 $3
elif [[ "$1" == "-sf" ]]; then
	showFile $2
elif [[ "$1" == "-fcom" ]]; then
	findInCommonAPI $@
elif [[ "$1" == "-sp" ]]; then
	showInfoProcess $2
elif [[ "$1" == "-cr" ]]; then #Create repository
	createRepository $2
elif [[ "$1" == "-kp" ]]; then # Kill other builds in processing
	killBuildProcess
# elif [[ "$1" == "-mfmfp" ]]; then # make files on MFP
	# makeFilesMFP | tee -a $logGCCMake
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
		elif [[ "$1" == "-mfmfp" ]]; then # make files on MFP machine.
			IS_MakeFilesMFP=True
		fi	
		shift
	done	
	FILE_BRANCH=$logFolder/info_start_build.txt
	mkdir -p ${gccOnlyFiles}/log
	listMakeFilesRepo=${gccOnlyFiles}/listMakeFilesRepo.txt; echo >>$listMakeFilesRepo
	listMakeFilesMFP=${gccOnlyFiles}/listMakeFilesMFP.txt; echo >>$listMakeFilesMFP
	# listMakeFilesDivlib=${gccOnlyFiles}/listMakeFilesDivlib.txt; echo >>$listMakeFilesDivlib
	echo action: $ACTION
	echo machine_type: $MACHINE_TYPE
	echo 
	# checking buildmfp.sh was existed or not
	check=`ps -ef | grep buildmfp.sh | grep -v grep`
	[ $? -ne 0 ] && exit 0
	[[ "$IS_BackupLog" == "True" ]] && backupLogs
	[[ "$IS_UpdatedSource" == "True" ]] && updateSource
	if [[ "$IS_MakeFilesMFP" == "True" ]]; then
		logGCCMake=${gccOnlyFiles}/log/logGCCMake-`date +%F_%H`.txt; echo > $logGCCMake
		echo logGCCMake=$logGCCMake
		makeFilesMFP | tee -a $logGCCMake
		exit 0
	fi
	[[ "$IS_Build" == "True" ]] && startBuild
	exit 0
fi

# Added more files to Repository
#while IFS= read -r line ; do echo $line; cp --parents $line ~/work/git/IT5_42_ZeusS_ZX0_SIM/; done < ~/work/list_file

