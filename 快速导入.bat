::�ű����ܣ�Oracle�������ݵ���
::�ű���д���ķ����� ŷ�ֺ�
::�汾��ʷ��
::          2016-12-22 Ver1.0
::                     ��ʼ�汾��֧���������ݵ��빦�ܣ�CSV��ʽ��
@echo off
title Oracle���ݵ��������й��� Ver1.0 ��by olh
::���������ӳ�
setlocal EnableDelayedExpansion
::�л��ַ�����
chcp 936>nul

::���ò���
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=���ݿ�����.txt
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%BIN_DIR%\test_conn.log

::��ȡ���ݿ�����ѡ��
type %DB_SETTING% | findstr "^dataSource">%DB_SETTING_TMP% 
for /f "delims="  %%a in ( %DB_SETTING_TMP% ) do if "%%a" neq "" set "%%a"
if not defined dataSource ( echo dataSourceδ���� && goto :configError )

echo ========dataSource:%dataSource%========

::�������ѡ���ַ�������
for /l %%i in (0,1,100) do if "!dataSource:~%%i,1!" == "" set /a dataSourceLen=%%i && goto :endfor2
:endfor2

type %DB_SETTING% | findstr "^%dataSource%">%DB_SETTING_TMP%

::��ȡ������
for /f "delims=@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::����������Ƿ�����
for %%a in ( dbName exportType dbcharset dbUser dbEncPasswd dbIp dbService ) do (
    if not defined %%a echo %%aδ���ã����飡 && set checkEnvFlag=fail
)
if defined checkEnvFlag goto :configError

set /a fileCount=0
for %%a in ( data\*.csv ) do (
    set "ctlFile=%CTL_DIR%\%%~na.ctl"
    set /a fileCount=!fileCount!+1
    if not exist !ctlFile! (
        echo Generate !ctlFile!
        echo Load Data>!ctlFile!
        echo Append>>!ctlFile!
        echo into table %%~na>>!ctlFile!
        echo fields terminated  by ^',^'>>!ctlFile!
        echo OPTIONALLY ENCLOSED BY ^'^"^'>>!ctlFile!
        echo TRAILING NULLCOLS>>!ctlFile!
        echo ^(>>!ctlFile!
        sed -n '1p' %%a>>!ctlFile!
        echo ^)>>!ctlFile!
    )
)
echo.
set /p needImport=�Ƿ�%DATA_DIR%Ŀ¼�е�%fileCount%�������ļ��������ݿ�(y-�ǣ�����-��):
if not "x%needImport%" == "xy" goto :end
echo.
::�������ݿ����Ӵ�
for /f "delims=" %%i in ( '%BIN_DIR%\szboc_decrypt "%dbEncPasswd%"' ) do set dbEnv=%dbUser%/%%i@%dbIp%/%dbService%

::�������ݿ�����
echo ���ڲ������ݿ�����...
if exist %DB_TEST_RES% del %DB_TEST_RES%
sqlplus -L -S %dbEnv% @%DB_TEST_SQL% %DB_TEST_RES%
if not exist %DB_TEST_RES% goto :connDatabaseError
if exist %DB_TEST_RES% findstr "success" %DB_TEST_RES% >nul || goto :connDatabaseError
echo ���ݿ����ӳɹ�
echo.

echo ��ʼ����...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo ���ڵ���!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=20000 silent=ALL direct=TRUE
    findstr /r "���سɹ� û�м���" %LOG_DIR%\!fileName!.log
    echo.
)



if exist %DB_TEST_RES% del %DB_TEST_RES%

:end
echo �������,��������˳�...
pause>nul
exit

:configError
echo ���޸����ú����ԣ�
echo ������ֹ,��������˳�...
pause>nul
exit

:connDatabaseError
echo.
echo.
echo �������ݿ�ʧ�ܣ��������ã�
echo ������ֹ,��������˳�...
pause>nul
exit