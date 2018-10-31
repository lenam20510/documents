@echo off

set documents=D:\documents
set workspaces=D:\workspaces
set user=root
set pass=linuxfum
set hostIP=192.168.56.102
echo "Copy %documents% to %user%@%hostIP%"

cd %documents%

set todayDate=%rawDate:~0,4%-%rawDate:~4,2%-%rawDate:~6,2%

REM Uncomment this section if you want to archive as one huge file
REM now that we have today's date we can archive our backup files
echo "Backup to ~/backup_config"
plink -pw %pass% %user%@%hostIP% ^
	mkdir -p ~/.ssh; ^
	mkdir -p ~/backup_config; ^
	cp ~/.bashrc ~/backup_config; ^
	cp ~/.vimrc ~/backup_config; ^
	cp ~/.bash_aliases ~/backup_config
	

REM This is actual all one command, however separated to separate lines for readability
REM echo "copy to %user%@%hostIP%:/root/work"
REM pscp -pw %pass% ^
	REM my_scripts\buildmfp.sh ^
	REM %user%@%hostIP%:/root/work

echo "Copy to %user%@%hostIP%:/root"
pscp -pw %pass% ^
	-r my_scripts\.vim ^
	my_scripts\.bash_aliases ^
	my_scripts\.bashrc ^
	my_scripts\.vimrc ^
	my_scripts\config.ini ^
	%user%@%hostIP%:/root

echo "Copy Pub_Key to %user%@%hostIP%:/root/.ssh"
pscp -pw %pass% Pub_Key\* %user%@%hostIP%:/root/.ssh

echo "Run setup_EvnUbuntu"
plink -pw %pass% %user%@%hostIP% ^
	. /root/.bash_aliases; ^
	chmod +x /root/work/buildmfp.sh; ^
	setup_EvnUbuntu
echo "copy listFile_Repository.txt to %user%@%hostIP%:/root/work"
cd %workspaces%
pscp -pw %pass% ^
	listFile_Repository.txt ^
	listFileInCommonAPI.txt ^
	%user%@%hostIP%:/root/work
GOTO END
REM return back to C
:END
C:
ECHO Successful!!!
PAUSE >NUL