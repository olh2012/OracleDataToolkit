::�ű����ܣ�Oracle�������ݵ����뵼��
::�ű���д���ķ����� ŷ�ֺ�
::�汾��ʷ��
::          2016-12-24 Ver1.3
::                     �ϲ������뵼�����ܣ�����Ӳ˵�������֧���������
::                     �����ʱ�л�����Դ����
::                     ���Ŀ¼������
::          2016-12-23 Ver1.2
::                     ������ݵ��빦�ܣ�֧���Զ���csv�ļ������ɿ����ļ�
::          2016-12-02 Ver1.1 
::                     ������ݿ����ü�������ʽ�����ݿ��ַ���������
::                     ������ݿ����Ӳ���
::          2016-11-03 Ver1.0
::                     ��ʼ�汾����ʵ���������ݵ�������
@echo off
title Oracle���������й��� Ver1.3 ��by ŷ�ֺ�
::���������ӳ�
setlocal EnableDelayedExpansion
::�л��ַ�����
chcp 437>nul
graftabl 936>nul

::���ò���
set CUR_DIR=%~dp0
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=���ݿ�����.txt
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%BIN_DIR%\test_conn.log
set path=%path%;%CUR_DIR%\%BIN_DIR%

::��ȡ���ݿ�����ѡ��
type %DB_SETTING% | findstr "^dataSource">%DB_SETTING_TMP%
for /f "delims="  %%a in ( %DB_SETTING_TMP% ) do if "%%a" neq "" set "%%a"

if not defined dataSource ( echo dataSourceδ���� && goto :configError )

:setDataSource
echo =========���ݿ�����:%dataSource%=========

::�������ѡ���ַ�������
set /a dataSourceLen=0
for /l %%i in (0,1,100) do if "!dataSource:~%%i,1!" == "" set /a dataSourceLen=%%i && goto :endfor2
:endfor2

findstr "^%dataSource%" %DB_SETTING%>%DB_SETTING_TMP%

::��ȡ������
for /f "delims=@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
set fillStr=
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::����������Ƿ�����
for %%a in ( dbName exportType dbcharset dbUser dbEncPasswd dbIp dbService ) do (
    if not defined %%a echo %%aδ���ã����飡 && set checkEnvFlag=fail
)
if defined checkEnvFlag goto :configError

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

:showMenu
echo.
echo (1) ���ݵ���        
echo (2) ���ݵ���
echo (3) �л�����Դ
echo (4) ����Ŀ¼
echo (5) �˳�����
echo --------------
echo ��ѡ��˵�
choix /c:12345 /M( /N 

for %%a in (1 2 3 4 5) do if errorlevel %%a set item=%%a
echo ��ѡ����%item%
if %item% equ 1 goto importData
if %item% equ 2 goto exportData
if %item% equ 3 goto changeDB
if %item% equ 4 goto cleanDir
if %item% equ 5 exit
goto end

:importData
set /a fileCount=0
for %%a in ( data\*.csv ) do (
    set "ctlFile=%CTL_DIR%\%%~na.ctl"
    set /a fileCount=!fileCount!+1
    if not exist !ctlFile! (
        echo �������ɿ����ļ�: !ctlFile!...
        echo Load Data>!ctlFile!
        echo Append>>!ctlFile!
        echo into table %%~na>>!ctlFile!
        echo fields terminated  by ^',^'>>!ctlFile!
        echo OPTIONALLY ENCLOSED BY ^'^"^'>>!ctlFile!
        echo TRAILING NULLCOLS>>!ctlFile!
        echo ^(>>!ctlFile!
        head -n 1 %%a>>!ctlFile!
        echo ^)>>!ctlFile!
    ) else (
        echo ��⵽ %%~na ��Ӧ�Ŀ����ļ��Ѵ���
    )
)
echo.
echo ����Ŀ¼���ܹ���%fileCount%���ļ����Ƿ�ȫ���������ݿ�?
echo;* Y-ȷ��
echo;* N-ȡ��
choix /c:YN /M- /N
if errorlevel 2 goto :showMenu

echo ��ʼ����...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo ���ڵ���!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=20000 silent=ALL direct=TRUE
    findstr /r "���سɹ� û�м���" %LOG_DIR%\!fileName!.log
    echo.
)
echo �������. 
goto continue

:exportData
echo ��ʼ����...
for %%a in ( %SQL_DIR%\*.sql ) do (
    echo ���ڵ���%%~na...
    sqluldr2 user=%dbEnv% sql=%%a file=%DATA_DIR%\%%~na.%exportType% text=%exportType% charset=%dbcharset%
)
echo �������.
goto continue

:changeDB
findstr "@dbName" %DB_SETTING%>%DB_SETTING_TMP%
set /a seqNo=0
set seqNoText=
:showDbConfig
echo.
echo ��ǰ�����õ�����Դ:
for /f "delims== tokens=2"  %%a in ( %DB_SETTING_TMP% ) do (
    set /a seqNo=seqNo+1
    set seqNoText=%seqNoText%%seqNo%
    echo;^(!seqNo!^) %%a 
)
echo ------------------
echo ��ѡ��
choix /c:123456789 /M( /N 
set item=%errorlevel%
if %item% gtr %seqNo% echo ��Ч��ѡ��,���������� && goto showDbConfig
set /a item=item-1
for /f "delims=@ tokens=1 skip=%item%" %%a in ( %DB_SETTING_TMP% ) do (
    set dataSource=%%a
    goto endfor3
)
:endfor3
echo ����Դ�������л�Ϊ%dataSource%
goto setDataSource

:cleanDir
echo ��ѡ��Ҫ�����Ŀ¼:
echo (1) �����ļ�Ŀ¼
echo (2) �����ļ�Ŀ¼
echo (3) ��־�ļ�Ŀ¼
echo (4) SQL�ļ�Ŀ¼
echo (5) ��SQL���ȫ��Ŀ¼
echo (6) ȫ��Ŀ¼
echo ------------------
echo ��ѡ��
choix /c:123456 /M( /N 
set item=%errorlevel%
echo ��ѡ����%item%
if %item% equ 1 del /q /f %DATA_DIR%\*.*
if %item% equ 2 del /q /f %CTL_DIR%\*.*
if %item% equ 3 del /q /f %LOG_DIR%\*.*
if %item% equ 4 del /q /f %SQL_DIR%\*.*
if %item% equ 5 del /q /f %DATA_DIR%\*.* %CTL_DIR%\*.* %LOG_DIR%\*.*
if %item% equ 6 del /q /f %DATA_DIR%\*.* %CTL_DIR%\*.* %LOG_DIR%\*.* %SQL_DIR%\*.*
echo �������.
goto continue


:continue
echo ��������������˵�
pause>nul
cls
goto showMenu

:end
if exist %DB_TEST_RES% del %DB_TEST_RES%
echo ��������˳�...
pause>nul
exit

:configError
echo ���޸����ú����ԣ�
goto continue

:connDatabaseError
echo.
echo.
echo �������ݿ�ʧ�ܣ��������ã�
goto continue