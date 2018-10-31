@echo off
REM cd /d %~dp0

REM set FULL_PATH=%~dp0
REM set FULL_PATH=%FULL_PATH:~1,-1%
REM for %%i in ("%FULL_PATH%") do set "PARENT_FOLDER=%%~ni"
REM REM set ovfname=%PARENT_FOLDER%
REM set OVFName=IT6_Sparrow_D0006_0514_4
REM set VIRTUALMACHINE_RAM=4096
REM set VIRTUALMACHINE_MAC=080027173B14

rem パスの追加
REM set PATH=%PATH%;C:\Program Files\Oracle\VirtualBox
set VBoxManage=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe


rem ディレクトリ名の設定
set dir1="新Sim環境"
set dir2="vdiファイル"

rem ストレージのアタッチ
cd .\%dir2% 
for /f "delims=" %%a in ('dir /B ^| findstr "kernel[^\\]*$"') do @set sata0=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "HDD[^\\]*$"') do @set sata1=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "SSD[^\\]*$"') do @set sata2=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "Sim[^\\]*$"') do @set sata3=%%a

REM cd ..

:attachsata0
@echo ->VBoxManage -nologo internalcommands sethduuid %sata0%
VBoxManage -nologo internalcommands sethduuid %sata0%

:attachsata1
@echo ->VBoxManage -nologo internalcommands sethduuid %sata1%
VBoxManage -nologo internalcommands sethduuid %sata1%

:attachsata2
@echo ->VBoxManage -nologo internalcommands sethduuid %sata2%
VBoxManage -nologo internalcommands sethduuid %sata2%

:attachsata3
@echo ->VBoxManage -nologo internalcommands sethduuid %sata3%
VBoxManage -nologo internalcommands sethduuid %sata3%

rem ネットワーク設定の変更
GOTO END
REM return back to C
:ERROR
ECHO FAILED!!!
PAUSE >NUL
:END
C:
ECHO Successful!!!
PAUSE >NUL