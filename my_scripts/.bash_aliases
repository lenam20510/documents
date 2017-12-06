#*****
#add to ~/.bashrc , then run: source ~/.bashrc
#if [ -f ~/.bash_aliases ]; then
#        . ~/.bash_aliases
#fi
#
#************export*************
# machine_type=mmlk # zsb2z
export REPO_NAME=IT6_Dev
export MACHINE_TYPE=a64_mv7040
export WORK=/root/work
export KM3=$WORK/KM3
export KM=$KM3/KM
export BUILD_SOURCE=${KM}/application
export REPO_2PORTLAN=$WORK/repository/${REPO_NAME}
export logFolder=$KM/work/${MACHINE_TYPE}/log
export MASTER_BRANCH=master
export SIM_IPaddress='192.168.56.102'

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

if [ ! -f ~/.inputrc ]; then
	echo '"\e[A": history-search-backward' > ~/.inputrc
	echo '"\e[B": history-search-forward' >> ~/.inputrc
	echo 'set show-all-if-ambiguous on' it>> ~/.inputrc
	echo 'set completion-ignore-case on' >> ~/.inputrc
fi

#*********Funtion*****************
#grep with extention *.cpp or/and *.h or anything else
function sgrep {
	pattern="$1"
	path="$2"
	exten="$3"
	addLine="${*:4}"
	includes="--include=*.h --include=*.cpp --include=*.c --include=MediaMapFile*"
	if [[ -z "$path" ]]; then
		path="."
	fi
	if [[ -n "$exten" ]]; then
		if [[ "$exten" == "h" || "$exten" == "cpp" || "$exten" == "c" ]]; then
			includes="--include=*.${exten}"
		elif [[ "$exten" != "-"* ]]; then
			includes="--include=*${exten}*"
		else
			addLine=${exten}
		fi
	fi
	includes+=" --exclude=*.bak --exclude=*.swp"
	#command="grep --color=auto ${addLine} -rna $includes $pattern $path"
	#echo $command
	#echo
	#$command
	echo "grep --color=auto ${addLine} -rna $includes \"$pattern\" $path"
	grep --color=auto ${addLine} -rna $includes "${pattern}" $path
}
function sfind {
	path='.'
	pattern=${1}
	notInclude="-not -name *.swp \
				-not -name *.swo \
				-not -name *.swn "

	if [ $# -gt 1 ]; then
		path=$1
		pattern=$2
	fi
	[[ "$pattern" != *"."* ]] && pattern=${pattern}*
	find $path -type f -iname *${pattern} \
		${notInclude} \
		|  head | grep --color=auto '^\|[^/]*$' #color
}
function rmswapfile {
	swapfile="-name *.swp \
			-o -name *.swo \
			-o -name *.swn "
	rm -v `find ${BUILD_SOURCE} ${REPO_2PORTLAN} -type f ${swapfile}`
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

alias 2portlan='cd ~/work/repository/IT5_42_2PortLan'
alias work='cd /root/work'
alias appsource='cd ~/work/KM3/KM/application'
alias apprepo='cd ~/work/repository/${REPO_NAME}/KM/application'
alias nvd_mfp='cd ~/work/KM3/KM/application/mfp/system/nvd'
alias nvd_divlib='cd ~/work/KM3/KM/application/divlib/client/Proxy/system/nvd'
alias errors='cat /root/work/KM3/KM/work/${MACHINE_TYPE}/log/errors.txt '
alias build_mfp='~/work/buildmfp.sh'
alias start_mount='~/work/start_mount.sh'
alias end_mount='~/work/end_mount.sh'
alias repo='cd ~/work/repository/${REPO_NAME}/'
alias startMFP='cd /root; ./start-mfp.sh | tee -a ~/work/startMFP/log_start-mfp_`date +%F_%H%M%S`.txt'

alias mkdir="mkdir -p"
alias lh='ls -lisAd .[^.]*'
alias la='ls -lisA'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias hs='history|grep -i '
alias pss='ps -axf | grep -v grep | grep -i $1'
alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'
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

