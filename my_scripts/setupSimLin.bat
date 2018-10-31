@echo off
cd /d %~dp0

rem SimLin初期構築自動化バッチ
rem できること
rem ・vdiファイルのインポート
rem ・HDDのアタッチ
rem ・ネットワークのMACアドレス初期化rem 
rem 
rem 更新履歴
rem 2018/2/22 初版発行
rem 2018/2/22 仮想マシンの重複チェックの追加
set FULL_PATH=%~dp0
set FULL_PATH=%FULL_PATH:~1,-1%
for %%i in ("%FULL_PATH%") do set "PARENT_FOLDER=%%~ni"
set ovfname=%PARENT_FOLDER%
set VIRTUALMACHINE_RAM=4096
set VIRTUALMACHINE_MAC=080027173B14

rem パスの追加
set PATH=%PATH%;C:\Program Files\Oracle\VirtualBox


rem ディレクトリ名の設定
set dir1="新Sim環境"
set dir2="vdiファイル"

rem OVFファイルのインポート
cd .\%dir1%
for /f "delims=" %%a in ('dir /B ^| findstr ".ovf[^\\]*$"') do @set ovffile=%%a
REM for /f "delims=" %%a in ('echo %ovffile%') do @set ovfname=%%a
REM for /f %%i in ('echo %ovffile%') do set ovfname=%%~ni
REM ovfname=%OVFName%

rem 重複チェック
for /f "tokens=1" %%a in ('VBoxManage list vms') do (
    if %%a=="%ovfname%" (
    @echo すでに%ovfname%が存在しています。削除するか名前を変更してください。
    cd ..
    set /P input=
    exit /B
  )
)

VBoxManage import %ovffile%
cd ..

rem ストレージのアタッチ
cd .\%dir2% 
for /f "delims=" %%a in ('dir /B ^| findstr "kernel[^\\]*$"') do @set sata0=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "HDD[^\\]*$"') do @set sata1=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "SSD[^\\]*$"') do @set sata2=%%a
for /f "delims=" %%a in ('dir /B ^| findstr "Sim[^\\]*$"') do @set sata3=%%a

rem VBoxManage storagectl %ovfname% --name SATA0 --portcount 1 --add sata
rem VBoxManage storagectl %ovfname% --name SATA1 --portcount 1 --add sata
rem VBoxManage storagectl %ovfname% --name SATA2 --portcount 1 --add sata
rem VBoxManage storagectl %ovfname% --name SATA3 --portcount 1 --add sata

VBoxManage storageattach %ovfname% --storagectl SATA --port 0 --type hdd --medium %sata0%
VBoxManage storageattach %ovfname% --storagectl SATA --port 1 --type hdd --medium %sata1%
VBoxManage storageattach %ovfname% --storagectl SATA --port 2 --type hdd --medium %sata2%
VBoxManage storageattach %ovfname% --storagectl SATA --port 3 --type hdd --medium %sata3%

cd ..

REM Memory updated
VBoxManage modifyvm %ovfname% --memory %VIRTUALMACHINE_RAM% --rtcuseutc on --acpi on --nic1 bridged --bridgeadapter1 eth2 --macaddress1 $VIRTUALMACHINE_MAC

rem MACアドレスの更新
VBoxManage modifyvm %ovfname%  --macaddress1 auto hostonly
VBoxManage modifyvm %ovfname%  --macaddress2 auto hostonly


rem ネットワーク設定の変更
GOTO END
REM return back to C
:END
C:
ECHO Successful!!!
PAUSE >NUL