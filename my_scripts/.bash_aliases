#*****
#add to ~/.bashrc , then run: source ~/.bashrc
#if [ -f ~/.bash_aliases ]; then
#        . ~/.bash_aliases
#fi
#
#************export*************
#export GCC='x86_64-linux-gcc'
USER=root
HOME=/root
export ARCH_FLD=${HOME}/arch
export PMAKE_FILE=pmake.sh
CURR_WORK=/root/work
CURR_DIR=`pwd`
export MY_WORK=${CURR_WORK}
file_config=$HOME/config.ini
if [ -f config.ini ]; then
	file_config='config.ini'
fi

if [ -f $file_config ]; then
	. $file_config
else
	export MACHINE_TYPE=zse800
	export ACTION=act2
	export QT_VERSION=q530
	export MODEL_NAME=Eagle
	export REPO_NAME=IT6_Eagle_D0010
	export MASTER_BRANCH=master
	export IPaddress='192.168.56.102'
fi
export file_aliase=${HOME}/.bash_aliases
#ROOT=`readlink -f $ROOT`
export MKINDEX_IT6=${CURR_WORK}/mkindex_IT6.sh
export MKINDEX_IT5=${CURR_WORK}/mkindex_Zeus5BK.sh
export U4E=${CURR_WORK}/u4e
export KM3=$CURR_WORK/KM3
export KM=$KM3/KM
export KM_APP=${KM}/application
export KM_WORK=${KM}/work
export KM_FW=$KM/pmake/${MACHINE_TYPE}/all/km/fw
export KM_FW_RE=$KM/pmake/${MACHINE_TYPE}/hw_release/km/fw
export MFP_SOURCE=${KM_APP}/mfp
export DIVLIB_SOURCE=${KM_APP}/divlib
export PMAKE_FLD=${KM}/pmake
export logFolder=$KM/work/${MACHINE_TYPE}/log
#export REPO_PATH=$CURR_WORK/git/${REPO_NAME}
export mountFolder=${CURR_WORK}/mountFolder
export extractSource=$mountFolder/extractSource
export REPO_PATH=$mountFolder/git/${REPO_NAME}
export gccOnlyFiles=${mountFolder}/gccOnlyFiles/${MACHINE_TYPE}-${REPO_NAME}
export startMFP=${mountFolder}/startMFP/${MACHINE_TYPE}-${REPO_NAME}
export buildLog=${mountFolder}/build-log/${MACHINE_TYPE}-${REPO_NAME}
export FILE_REPO=${mountFolder}/listFile_Repository.txt
export CSCOPE_DB=cscope.out
export CSCOPE_EDITOR=vim

git config --global core.safecrlf false
git config --global push.default current
git config --global color.ui true
#export GREP_OPTIONS='--color=always'

export LS_OPTS='--color=auto'
if [ ! -f ~/.vimrc ]; then
  echo 'syntax on' > ~/.vimrc
  #echo 'set number' >> ~/.vimrc
  echo 'colorscheme desert' >> ~/.vimrc
  echo 'set list listchars=tab:\|\ 
highlight Whitespace cterm=underline gui=underline ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow
autocmd ColorScheme * highlight Whitespace gui=underline ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow
match Whitespace /  \+/' >> ~/.vimrc
fi

#bind '"\e[A": history-search-backward'
#bind '"\e[B": history-search-forward'
if [ ! -f ~/.inputrc ]; then
	echo '"\e[A": history-search-backward' > ~/.inputrc
	echo '"\e[B": history-search-forward' >> ~/.inputrc
	echo 'set show-all-if-ambiguous on' it>> ~/.inputrc
	echo 'set completion-ignore-case on' >> ~/.inputrc
fi

#*********Funtion*****************
#grep with extention *.cpp or/and *.h or anything else

function mountFld {
	option=$1
	if [ -z $option ]; then
		file=/tmp/mountFld.txt
		echo "`mount -t vboxsf | grep /media`" > $file; echo >> $file
		while IFS= read -r line 
		do
			[[ ! -n $line ]] && continue
			destination=`echo $line | awk '{print $1}'`; des_path=$MY_WORK/$destination
			mkdir -p $des_path; mount -t vboxsf $destination $des_path
			echo $des_path
		done < $file
	else
		if [[ "$option" == "-i" ]]; then
			CURR_DIR=`pwd`;cd /root/work/;mkdir cdroom;mount /dev/cdrom cdroom;cd cdroom;echo yes | ./VBoxLinuxAdditions.run;cd $CURR_DIR
		else
			des_path=$MY_WORK/$option;mkdir -p $des_path; mount -t vboxsf $option $des_path;echo $des_path
		fi
	fi
}
function clearNVRAM {
	rm -fr /Virtual_NVRAM/*
	rm -fr /Virtual_SPI-Flash/*
	yes | mkfs.ext3 /dev/sdc10
}

function sgrep {
	path=
	options=
	includes=
	pattern="$1"
	exclude_dir=
	is_multi=
	shift
	
	while [[ -n "$1" ]]; do
		if [[ "$1" == "-e" ]]; then
			shift
			pattern="-e${pattern} -e$1"
			is_multi=True
		elif [[ "$1" == "-"* ]]; then
			options+=" $1"
		elif [[ "$1" == "all" ]]; then
			includes=" --include=*"
		elif [[ "$1" == "." && `echo $1 | wc -w` -eq 1 || "$1" == *"/"* ]]; then
			path=$1
		elif [[ "$1" == "."* ]]; then
			includes+=" --include=*${1}"
		else
			includes+=" --include=*${1}*"
		fi	
		shift
	done	
	
	if [[ -z "$includes" ]]; then
		includes="--include=*.h --include=*.cpp --include=*.c --include=MediaMapFile*"
	fi
	if [[ -z "$path" ]]; then
		path="."
	fi
	includes+=" --exclude=*.bak --exclude=*.swp"
	options+=" -rna"
	echo "grep --color=auto ${options} $includes "${pattern}" $path"
	if [[ "$is_multi" == "True" ]]; then
		grep --color=auto ${options} $includes ${pattern} $path
	else
		grep --color=auto ${options} $includes "${pattern}" $path
	fi
}
function sfind {
	options=
	path=
	pattern=
	notInclude="-not -name *.swp \
				-not -name *.swo \
				-not -name *.swn "

	while [[ -n "$1" ]]; do
		if [[ "$1" == "-"* ]]; then
			options+=" $1"
		elif [[ "$1" == "." && `echo $1 | wc -w` -eq 1 || "$1" == *"/"* ]]; then
			path=$1
		else
			pattern=$1
		fi	
		shift
	done
	[[ "$pattern" != *"."* ]] && pattern=${pattern}*
	echo "find $path -type f ${options} -iname *${pattern} ${notInclude} "
	find $path -type f ${options} -iname *${pattern} \
		${notInclude} \
		|  head | grep --color=auto '^\|[^/]*$' #color
}

function rmswapfile {
	swapfile="-name *.swp \
			-o -name *.swo \
			-o -name *.bak \
			-o -name *.rej \
			-o -name *.orig \
			-o -name *.swn "
	rm -v `find ${KM_APP} ${REPO_PATH} -type f ${swapfile}`
}
function fgtab {
  echo "tput setf/setb - Foreground/Background table"
  for f in {0..7}; do
    for b in {0..7}; do
      echo -en "$(tput setf $f)$(tput setb $b) $f/$b "
    done
    echo -e "$(tput sgr 0)"
  done
}

function git_pull {
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo "git pull origin $branch"
	git pull origin $branch
}
function git_push {
	local branch=`git rev-parse --abbrev-ref HEAD`
	echo "git push origin ${branch}:${branch}"
	git push origin ${branch}:${branch}
}
function csSource {
	CURR_DIR=`pwd`
	arrs=($REPO_PATH $KM)
	for path in ${arrs[*]}
	do
		cd $path/application
		find mfp/ divlib/ -type f -name *.h -o -name *.cpp -o -name *.c | sort -u > cscope.files; cscope -bv; ctags -R mfp/* divlib/*
	done
	cd $CURR_DIR
}
function setup_Config {
	echo "->setup_Config..."
	cd $PMAKE_FLD
	machine_type=`ls -d */ | grep -v make | grep -v log | head -n1 | cut -d '/' -f1`
	echo machine_type:$machine_type
	repo_name_tmp=`grep echo.*${machine_type} pmake.sh | head -n1`
	repo_name_tmp=${repo_name_tmp##*${machine_type}}
	repo_name_tmp=`echo $repo_name_tmp | cut -d ':' -f2 | cut -d '"' -f1 | cut -d ' ' -f1`
	repo_name_tmp=`echo $repo_name_tmp | sed 's/\\///g'`
	echo repo_name_tmp:$repo_name_tmp
	model_name=${repo_name_tmp}; [ $machine_type == *800 ] && model_name=${model_name}Emu800

	[ -n ${machine_type} ] && sed -i 's/MACHINE_TYPE=.*$/'MACHINE_TYPE=${machine_type}'/g' $HOME/config.ini
	[ -n ${model_name} ] && sed -i 's/MODEL_NAME=.*$/'MODEL_NAME=${model_name}'/g' $HOME/config.ini
	
	file_ROMVersion=${MFP_SOURCE}/system/sys/RomVersion/RomVersionIntegration/SYSC_RomVersionInt.h
	[ -f $file_ROMVersion ] && ROMVersion=`grep TYPD_SysRomversionIntFW $file_ROMVersion | tail -n1 | awk '{print $NF}' | cut -d '"' -f2 | cut -d '(' -f1 | sed s/-//g`
	
	repo_name=IT6_${repo_name_tmp}_${ROMVersion}
	[ -n ${repo_name} ] && sed -i 's/REPO_NAME=.*$/'REPO_NAME=${repo_name}'/g' $HOME/config.ini
	cd $CURR_DIR
}
function setup_EvnUbuntu {
#echo 'MaxStartups 100' > /etc/ssh/sshd_config
echo "->ssh configure..."
mkdir -p ~/.ssh
cp ~/.vim/public_key/* ~/.ssh/
chmod 500 /root/.ssh/id_rsa
chmod 700 /root/.ssh/id_rsa.pub
echo "->Git configuring..."
git config --global user.email "namml@gcs-vn.com"
git config --global user.name "Le Nam"
#echo "->Setup networking..."
	#echo 'auto eth2
#iface eth2 inet dhcp
#iface eth2 inet static
#address 192.168.106.150' >> /etc/network/interfaces
#/etc/init.d/networking restart
echo "->Setup LANG..."
echo 'LANG="en_US.Shift-JIS"
LANGUAGE="en_US.Shift-JIS"
LC_CTYPE="en_US.Shift-JIS"
LC_NUMERIC="en_US.Shift-JIS"
LC_TIME="en_US.Shift-JIS"
LC_COLLATE="en_US.Shift-JIS"
LC_MONETARY="en_US.Shift-JIS"
LC_MESSAGES="en_US.Shift-JIS"
LC_PAPER="en_US.Shift-JIS"
LC_NAME="en_US.Shift-JIS"
LC_ADDRESS="en_US.Shift-JIS"
LC_TELEPHONE="en_US.Shift-JIS"
LC_MEASUREMENT="en_US.Shift-JIS"
LC_IDENTIFICATION="en_US.Shift-JIS"
' > /etc/default/locale
echo 'LANG=en_US
LANGUAGE=en_US' > vi ~/.pam_environment

setup_Config
echo "->Instal plugin..."
dpkg -i ~/.vim/exuberant-ctags_5.9_svn20110310-11_i386.deb
tar -xvf ~/.vim/cscope-15.8b.tar.gz; cd cscope-15.8b; ./configure; export LDFLAGS="$LDFLAGS -ltinfo"; make; make install; cd ..; rm -rf cscope-15.8b
echo "->Install vboxsf..."
mountFld mountFolder
[ ! -f $mountFolder/buildmfp.sh ] && `mountFld -i; mountFld mountFolder`

}

extract () {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvjf $1    ;;
           *.tar.gz)    tar xvzf $1    ;;
           *.bz2)       bunzip2 $1     ;;
           *.BZ2)       bunzip2 $1     ;;
           *.rar)       unrar x $1     ;;
           *.gz)        gunzip $1      ;;
           *.tar)       tar xvf $1     ;;
           *.tbz2)      tar xvjf $1    ;;
           *.tgz)       tar xvzf $1    ;;
           *.zip)       unzip $1       ;;
           *.Z)         uncompress $1  ;;
           *.7z)        7z x $1        ;;
           *)           echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
}

#***********Alias****************
# reboot / halt / poweroff
alias ports='netstat -tulanp'
# This is GOLD for finding out what is taking so much space on your drives!
alias diskspace="du -S | sort -n -r |more"

alias work='cd $MY_WORK'
alias appsource='cd $KM_APP'
alias appemu800='cd /root/work/Emu800/KM3/KM/application'
alias apprepo='cd ${REPO_PATH}/application'
alias nvd_mfp='cd $MFP_SOURCE/system/nvd'
alias nvd_divlib='cd $DIVLIB_SOURCE/client/Proxy/system/nvd'
alias errors='cat $buildLog/errors.txt '
alias build_mfp='$mountFolder/buildmfp.sh'
alias repo='cd ${REPO_PATH}'
alias logFolder='cd $logFolder'

alias mkdir="mkdir -p"
alias lh='ls -lisAd .[^.]*'
alias la='ls -lisA'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias hs='history|grep -i '
alias pss='ps -axf | grep -v grep | grep -i $1'
alias showtree='find $1 -type d | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'
alias vi='vim'

alias git_log="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
#alias git_pull="_git_pull_"
#alias git_push="_git_push_"
alias git_tag="git tag -a"
alias git_view_tag="git cat-file tag"
#alias find_grep='find "$2"  -type f -name *.h -o -name *.cpp'
#alias myalias='function __myalias() { echo "Hello $*, $1, $2"; myresult=$?; unset -f __myalias; return $myresult; }; __myalias'

#************Common******************
#export PS1="\e[0;31m[\u@\h \W]\$ \e[m "
#PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '

# The prompt in a somewhat Terminal -type independent manner:
cname="$(tput setf 3)"
csgn="$(tput setf 4)"
chost="$(tput setf 2)"
cw="$(tput setf 6)"
crst="$(tput sgr 0)"
#PS1="\[${cname}\]\u\[${csgn}\]@\[${chost}\]\h:\[${cw}\]\w\[${csgn}\]\n\$\[${crst}\] "

RESET="\[\017\]"
BLUE="\[\033[0;34m\]"
NORMAL="\[\033[0m\]"
RED="\[\033[31;1m\]"
YELLOW="\[\033[33;1m\]"
WHITE="\[\033[37;1m\]"
CYAN='\e[0;36m'
LIGHT_CYAN='\e[1;36m'
GRAY='\e[0;30m'
LIGHT_BLUE='\e[1;34m'
GREEN='\e[0;32m'
LIGHT_GREEN='\e[1;32m'
PURPLE='\e[0;35m'

SMILEY="${WHITE}:)${NORMAL}"
DATE="${BLUE}[$(date +%m/%d)]"
FROWNY="${RED}:(${NORMAL}"
#Auto run ad Startup
mountFld
[ ! -f $mountFolder/buildmfp.sh ] && mountFld mountFolder
[ ! -f $REPO_PATH/config.ini ] && cp $file_config $REPO_PATH/config.ini
#Support git PS1
[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /etc/bash_completion.d/git-prompt ] && source /etc/bash_completion.d/git-prompt
#PS1="[\[\033[32m\]\w]\[\033[0m\]\$(__git_ps1)\n\[\033[1;36m\]\u\[\033[32m\]$ \[\033[0m\]"
# Throw it all together 
#PS1="${RESET}${YELLOW}\h${NORMAL} \`${SELECT}\` ${YELLOW}>${NORMAL} "
#PS1="\[${DATE}\]\[${cw}\]\w\[${csgn}\]\n\`${SELECT}\`${BLUE} ->\[${crst}\] "
SELECT="if [ \$? = 0 ]; then echo \"${SMILEY}\"; else echo \"${FROWNY}\"; fi"
PS1="\`${SELECT}\` \[${cw}\][\w]\[${csgn}\]\[\033[0m\]\$(__git_ps1)\n${BLUE}->\[${crst}\] "

#PS1="[\w]\\$ "