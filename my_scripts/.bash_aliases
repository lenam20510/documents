#*****
#add to ~/.bashrc , then run: source ~/.bashrc
#if [ -f ~/.bash_aliases ]; then
#        . ~/.bash_aliases
#fi
#
#************export*************
# machine_type=mmlk # zsb2z
export MACHINE_TYPE=zsze3
export ACTION=act2
export QT_VERSION=q530
export MASTER_BRANCH=master
export SIM_IPaddress='192.168.56.102'
export WORK=/root/work
export KM3=$WORK/KM3
export KM=$KM3/KM
export BUILD_SOURCE=${KM}/application
export KM_WORK=${KM}/work
export logFolder=$KM/work/${MACHINE_TYPE}/log
export REPO_NAME=IT6_Dev_1
export REPO_PATH=$WORK/git/${REPO_NAME}

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

function sgrep {
	path=
	options=
	includes=
	pattern="$1"
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
	rm -v `find ${BUILD_SOURCE} ${REPO_PATH} -type f ${swapfile}`
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
alias reboot='sudo /sbin/reboot'
alias poweroff='/root/work/end_mount.sh; sleep 5;sudo /sbin/poweroff'
alias halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'
alias ports='netstat -tulanp'
# This is GOLD for finding out what is taking so much space on your drives!
alias diskspace="du -S | sort -n -r |more"

alias work='cd /root/work'
alias appsource='cd ~/work/KM3/KM/application'
alias apprepo='cd ${REPO_PATH}/application'
alias nvd_mfp='cd ~/work/KM3/KM/application/mfp/system/nvd'
alias nvd_divlib='cd ~/work/KM3/KM/application/divlib/client/Proxy/system/nvd'
alias errors='cat /root/work/KM3/KM/work/${MACHINE_TYPE}/log/errors.txt '
alias build_mfp='~/work/buildmfp.sh'
alias start_mount='~/work/start_mount.sh'
alias end_mount='~/work/end_mount.sh'
alias repo='cd ${REPO_PATH}'
alias startMFP='cd /root; ./start-mfp.sh | tee -a ~/work/startMFP/log_start-mfp_`date +%F_%H%M%S`.txt'
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


#Support git PS1
[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /etc/bash_completion.d/git-prompt ] && source /etc/bash_completion.d/git-prompt
#PS1="[\[\033[32m\]\w]\[\033[0m\]\$(__git_ps1)\n\[\033[1;36m\]\u\[\033[32m\]$ \[\033[0m\]"
# Throw it all together 
#PS1="${RESET}${YELLOW}\h${NORMAL} \`${SELECT}\` ${YELLOW}>${NORMAL} "
#PS1="\[${DATE}\]\[${cw}\]\w\[${csgn}\]\n\`${SELECT}\`${BLUE} ->\[${crst}\] "
SELECT="if [ \$? = 0 ]; then echo \"${SMILEY}\"; else echo \"${FROWNY}\"; fi"
PS1="\`${SELECT}\` \[${cw}\][\w]\[${csgn}\]\[\033[0m\]\$(__git_ps1)\n${BLUE}->\[${crst}\] "

