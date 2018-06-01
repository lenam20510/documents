@echo off

set documents=D:\documents
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
	cp ~/.bash_aliases ~/backup_config; ^
	

REM This is actual all one command, however separated to separate lines for readability
echo "copy to %user%@%hostIP%:/root/work"
pscp -pw %pass% ^
	my_scripts\buildmfp.sh ^
	%user%@%hostIP%:/root/work

echo "Copy to %user%@%hostIP%:/root"
pscp -pw %pass% ^
	-r my_scripts\.vim ^
	my_scripts\.bash_aliases ^
	my_scripts\.bashrc ^
	my_scripts\.vimrc ^
	%user%@%hostIP%:/root

echo "Copy Pub_Key to %user%@%hostIP%:/root/.ssh"
pscp -pw %pass% Pub_Key\* %user%@%hostIP%:/root/.ssh

echo "Run setup_EvnUbuntu"
plink -pw %pass% %user%@%hostIP% ^
	. /root/.bash_aliases; ^
	chmod +x /root/work/buildmfp.sh; ^
	setup_EvnUbuntu

REM return back to C
:END
C:
ECHO Successful!!!
PAUSE >NUL