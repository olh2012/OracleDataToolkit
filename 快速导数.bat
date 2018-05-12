::�ű����ܣ�Oracle�������ݵ����뵼��
::�ű���д���ķ����� ŷ�ֺ�
::�汾��ʷ��
::          2018-05-11 Ver2.0
::                       ���ӽ��ܷ����л�ΪBASE64
::          2018-04-24 Ver1.9
::                       Ϊ���������ı����ݵ�����Ӷ����ȷ�ϲ���
::          2017-09-16 Ver1.8
::                       �����ݿ������ļ����޸�ΪINI��ʽ
::                       �����CSV�ļ��е������ܳ��ȳ���1024�ֽ�ʱ���ɵ�CTL�ļ��ж�ʧ������
::                       ��������������importMode������ָ��ִ��sqlldrʱʹ�õ�װ�ط�ʽ
::                       ��������ѡ���Ĭ��ֵ���ã�����exportType��importMode��fieldSeperator��recordSeperator��dbCharset��dbHostPort
::          2017-09-12 Ver1.7
::                       ���ӽ��ܵĳ���汾���µ�2.2
::                       ������ķָ����޸�Ϊ"@@"�����ֵ�����@@����ʹ��^@^@
::          2017-04-08 Ver1.6
::                       ���64λ����ϵͳ֧�֣�����Ƿ����������������ã���32λϵͳ��Ч��
::                       �����������ļ��ĸ�ʽ�޶�Ϊcsv��txt
::          2017-03-30 Ver1.5
::                       �������δ���õ�����
::                       ��������ݿ���������������dbPassword��ԭ����֧������������dbEncPassword��
::          2016-12-26 Ver1.4
::                       ���ֱ�Ӱ������ݿ���嵥�������ݹ���
::                       ������ݿ�˿�������dbHostPort
::                       ��ӵ��������ֶηָ�������fieldSeperator
::                       ��ӵ������ݼ�¼�ָ�������recordSeperator
::          2016-12-24 Ver1.3
::                       �ϲ������뵼�����ܣ�����Ӳ˵�������֧���������
::                       �����ʱ�л����ݿ⹦��
::                       ���Ŀ¼������
::          2016-12-23 Ver1.2
::                       ������ݵ��빦�ܣ�֧���Զ���csv�ļ������ɿ����ļ�
::          2016-12-02 Ver1.1 
::                       ������ݿ����ü�������ʽ�����ݿ��ַ���������
::                       ������ݿ����Ӳ���
@echo off
::���������ӳ�
setlocal EnableDelayedExpansion

::����32λϵͳ��64λϵͳִ�б�ʶ
if /i "%PROCESSOR_IDENTIFIER:~0,3%"=="x86" (
    set "WIN_BIT=Win32" 
    set "ONLY_X64=REM"
) else (
    set "WIN_BIT=Win64" 
    set "ONLY_X86=REM"
)

title Oracle���ٵ������� Ver2.0(%WIN_BIT%) ��by ŷ�ֺ�

::�л��ַ�����
%ONLY_X64% chcp 936>nul
%ONLY_X86% chcp 437>nul
%ONLY_X86% graftabl 936>nul
::����������ɫ
color 0a

::���ò���
set CUR_DIR=%~dp0
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=���ݿ�����.ini
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_PWD_TMP=%BIN_DIR%\dbPwd
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%LOG_DIR%\test_conn_res.log
set DB_TEST_INFO=%LOG_DIR%\test_conn_info.log
set path=%path%;%CUR_DIR%\%BIN_DIR%
set TAB_LIST=%SQL_DIR%\table_list.txt
set CHOICE_TIPS=��ѡ��˵�

::ִ�л������
::���Oracle�����й����Ƿ����
for %%a in ( sqlplus.exe sqlldr.exe ) do (
    where %%a 1>nul 2>nul || ( echo Oracle������ %%a δ�ҵ�����ȷ�ϱ����Ƿ�װ�˴������й��ߵ�Oracle. && goto end )
)

::���BINĿ¼�еĿ�ִ���ļ��Ƿ�ȱʧ
for %%a in ( sqluldr2.exe head.exe choix.com ) do (
    if not exist %BIN_DIR%\%%a echo ȱ�ٳ��������ļ�: %BIN_DIR%\%%a && goto end
)

::Ŀ¼��ʼ��
for %%a in ( %SQL_DIR% %CTL_DIR% %DATA_DIR% %LOG_DIR% ) do if not exist %%a md %%a

::��ȡ���ݿ�����ѡ��
type %DB_SETTING% | findstr "^dataSource ^mouseEnable">%DB_SETTING_TMP%
for /f "delims= "  %%a in ( %DB_SETTING_TMP% ) do if "x%%a" neq "x" set "%%a"

if not defined dataSource ( echo dataSourceδ���� && goto configError )
::����������,64λ����ģʽ��֧�����
set "ONLY_KEYBOARD="
set "SUPPORT_MOUSE=REM"
%ONLY_X86% if /i "%mouseEnable%" == "true" ( set "ONLY_KEYBOARD=REM" && set "SUPPORT_MOUSE=" )
%SUPPORT_MOUSE% set CHOICE_TIPS=%CHOICE_TIPS%(֧�������)

:setDataSource
echo ==========���ݿ�����:%dataSource%==========

::�������ѡ���ַ�������
set /a dataSourceLen=0
for /l %%i in (0,1,100) do if "x!dataSource:~%%i,1!" == "x" set /a dataSourceLen=%%i && goto endfor2
:endfor2

::����������
for %%a in ( dbName exportType importMode fieldSeperator recordSeperator dbCharset dbUser dbPassword dbEncPassword dbHostIp dbHostPort dbService ) do set %%a=

findstr "^%dataSource%" %DB_SETTING%>%DB_SETTING_TMP%

::��ȡ������
for /f "delims=@@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
set fillStr=
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::����������Ƿ�����
for %%a in ( dbName dbUser dbHostIp dbService ) do (
    if not defined %%a echo %%aδ���ã����飡 && set checkEnvFlag=fail
)
if not defined dbPassword if not defined dbEncPassword echo ���ݿ�����δ����! && set checkEnvFlag=fail
if defined checkEnvFlag goto configError

::����������Ĭ��ֵ
if not defined exportType set exportType=csv
if not defined importMode set importMode=Append
if not defined fieldSeperator set fieldSeperator=,
if not defined recordSeperator set recordSeperator=0x0a
if not defined dbCharset set dbCharset=gbk
if not defined dbHostPort set dbHostPort=1521

::�������ݿ����Ӵ�
set passwordStr=
if defined dbEncPassword (
    echo %dbEncPassword%>%DB_PWD_TMP%.tmp
    if exist %DB_PWD_TMP%.out del %DB_PWD_TMP%.out
    certutil -decode %DB_PWD_TMP%.tmp %DB_PWD_TMP%.out>nul
    for /f %%i in ( %DB_PWD_TMP%.out ) do (
        if "x%%i" == "x" echo ���ݿ������޷����� && goto configError
        set passwordStr=%%i
    )
    if exist %DB_PWD_TMP%.* del %DB_PWD_TMP%.*
) else (
    set passwordStr=%dbPassword%
)
set dbEnv=%dbUser%/%passwordStr%@%dbHostIp%:%dbHostPort%/%dbService%

::�������ݿ�����
echo ���ݿ�������֤��...
if exist %DB_TEST_RES% del %DB_TEST_RES%
sqlplus -L -S %dbEnv% @%DB_TEST_SQL% %DB_TEST_RES%>%DB_TEST_INFO%
findstr "success" %DB_TEST_RES% 1>nul 2>nul && echo ���ݿ����ӳɹ� || goto connDatabaseError

:showMenu
echo.
echo   (1) ��������
echo   (2) ��������
echo   (3) �л����ݿ�
echo   (4) ����Ŀ¼
echo   (5) �˳�����
echo ------------------------
%ONLY_KEYBOARD% choice /c:12345 /n /m "%CHOICE_TIPS%"
%SUPPORT_MOUSE% choix /c:12345 /n /m( "%CHOICE_TIPS%"

set item=%errorlevel%
if %item% equ 5 exit
%SUPPORT_MOUSE% echo ��ѡ����%item%
if %item% equ 1 goto importData
if %item% equ 2 goto exportData
if %item% equ 3 goto changeDB
if %item% equ 4 goto cleanDir
goto end

:importData
set /a fileCount=0
for %%a in ( %DATA_DIR%\*.csv %DATA_DIR%\*.txt ) do (
    set fileName=%%~na
    set fileExtName=%%~xa
    set "ctlFile=%CTL_DIR%\!fileName!.ctl"
    set /a fileCount=!fileCount!+1
    if /i "x!fileExtName!" equ "x.csv" (    
        if not exist !ctlFile! (
            echo !fileCount!.�����ļ���%%a
            echo   �������ɿ����ļ�: !ctlFile!...
            echo Load Data>!ctlFile!
            echo %importMode%>>!ctlFile!
            echo Into Table %%~na>>!ctlFile!
            echo Fields Terminated  by ^',^'>>!ctlFile!
            echo OPTIONALLY ENCLOSED BY ^'^"^'>>!ctlFile!
            echo TRAILING NULLCOLS>>!ctlFile!
            echo ^(>>!ctlFile!
            head -n 1 %%a>>!ctlFile!
            echo ^)>>!ctlFile!
        ) else (
            echo !fileCount!.�����ļ���%%a
            echo   �Ѿ����ڵĿ����ļ�: !ctlFile!
        )
    ) else (
        if not exist !ctlFile! (
            echo �����ļ� %%a ȱ�ٶ�Ӧ�Ŀ����ļ�����������.
            set /a fileCount=!fileCount!-1
        ) else (
            echo !fileCount!.�����ļ���%%a
            echo   �Ѿ����ڵĿ����ļ�: !ctlFile!
        )
    )
)
echo.
if %fileCount% equ 0 echo û��Ҫ����������ļ� && goto continue
echo Ҫ����%fileCount%���ļ����롾%dbName%����?
echo; * Y-ȷ��
echo; * N-ȡ��
%ONLY_KEYBOARD% choice /c:YN /n
%SUPPORT_MOUSE% choix /c:YN /n /m*
if errorlevel 2 echo ��ѡ����N && goto showMenu
echo ��ѡ����Y
::ȷ���Ƿ�Ϊ��������
set confirmStr=
set localIp=
for /f "tokens=4" %%a in ('route print^|findstr 0.0.0.0.*0.0.0.0') do set localIp=%%a
if "x%localIp:~0,6%" == "x10.100" (
    set /p confirmStr=��ǰΪ����������������YESȷ�����:
    if not "x!confirmStr!" == "xYES" echo ��ȡ���˱��β��� && goto continue
)

echo.
echo �������ݿ�ʼ...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo ���ڵ���!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=200000 silent=HEADER direct=TRUE
    findstr /r "���سɹ� û�м���" %LOG_DIR%\!fileName!.log
    echo.
)
for %%a in ( %DATA_DIR%\*.txt ) do (
    set fileName=%%~na
    set fileExtName=%%~xa
    if exist %CTL_DIR%\!fileName!.ctl (
        echo ���ڵ���!fileName!...
        sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!!fileExtName! bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=0 rows=20000 silent=HEADER direct=TRUE
        findstr /r "���سɹ� û�м���" %LOG_DIR%\!fileName!.log
        echo.
    )
)
echo �������ݽ���. 
goto continue

:exportData
echo �������ݿ�ʼ...
if exist %TAB_LIST% (
    echo ִ�б��嵥�����ݵ���...
    for /f "eol=# delims=" %%a in ( %TAB_LIST% ) do (
        if "x%%a" neq "x" (
            for /f "delims= " %%i in ( "%%a" ) do set dataFileName=%%i
            echo ���ڵ��� !dataFileName!...
            sqluldr2 user=%dbEnv% query="select * from %%a" file=%DATA_DIR%\!dataFileName!.%exportType% text=%exportType% charset=%dbCharset% field="%fieldSeperator%" record="%recordSeperator%" rows=500000
        )
    )
)
echo.
if exist %SQL_DIR%\*.sql echo ִ��SQL�ļ������ݵ���...
for %%a in ( %SQL_DIR%\*.sql ) do (
    echo ���ڵ��� %%~na...
    sqluldr2 user=%dbEnv% sql=%%a file=%DATA_DIR%\%%~na.%exportType% text=%exportType% charset=%dbCharset% field="%fieldSeperator%"  record="%recordSeperator%" rows=500000
)
echo �������ݽ���.
goto continue

:changeDB
echo ���ݿ��б�>%DB_SETTING_TMP%
findstr "@@dbName" %DB_SETTING%>>%DB_SETTING_TMP%
set /a seqNo=0
set seqNoText=
echo.
echo ��ǰ�����õ����ݿ�:
for /f "delims== tokens=2"  %%a in ( %DB_SETTING_TMP% ) do (
    set /a seqNo=seqNo+1
    set seqNoText=%seqNoText%%seqNo%
    echo;  ^(!seqNo!^) %%a
    if !seqNo! equ 9 goto endfor4
)
:endfor4
echo ------------------------
%ONLY_KEYBOARD% choice /c:123456789 /n /m "��ѡ��"
%SUPPORT_MOUSE% choix /c:123456789 /n /m( "��ѡ��"
set item=%errorlevel%
%SUPPORT_MOUSE% echo ��ѡ����%item%
if %item% gtr %seqNo% echo ��Ч��ѡ��,���������� && goto changeDB
for /f "delims=@@ tokens=1 skip=%item%" %%a in ( %DB_SETTING_TMP% ) do (
    set dataSource=%%a
    goto endfor3
)
:endfor3
echo ���ݿ��������л�Ϊ%dataSource%
goto setDataSource

:cleanDir
echo ��ѡ��Ҫ�����Ŀ¼:
echo   (1) �����ļ�Ŀ¼
echo   (2) �����ļ�Ŀ¼
echo   (3) ��־�ļ�Ŀ¼
echo   (4) SQL�ļ�Ŀ¼
echo   (5) ��SQL���ȫ��Ŀ¼
echo   (6) ȫ��Ŀ¼
echo   (7) ȡ������
echo ------------------------
%ONLY_KEYBOARD% choice /c:1234567 /n /m "��ѡ��"
%SUPPORT_MOUSE% choix /c:1234567 /n /m( "��ѡ��"
set item=%errorlevel%
%SUPPORT_MOUSE% echo ��ѡ����%item%
if %item% equ 1 call :cleanDir %DATA_DIR%\*.*
if %item% equ 2 call :cleanDir %CTL_DIR%\*.ctl
if %item% equ 3 call :cleanDir %LOG_DIR%\*.log
if %item% equ 4 call :cleanDir %SQL_DIR%\*.sql
if %item% equ 5 for %%a in (%DATA_DIR%\*.* %CTL_DIR%\*.ctl %LOG_DIR%\*.log) do call :cleanDir %%a
if %item% equ 6 for %%a in (%DATA_DIR%\*.* %CTL_DIR%\*.ctl %LOG_DIR%\*.log %SQL_DIR%\*.sql) do call :cleanDir %%a
if %item% neq 7 echo �������.
goto continue

:cleanDir
if "x%1" neq "x" (
    if exist "%1" del /q /f /s "%1"
)
goto :EOF


:continue
%SUPPORT_MOUSE% choix /c /n /m "�������������������˵�..."
%ONLY_KEYBOARD% echo ��������������˵�...
%ONLY_KEYBOARD% pause>nul
cls
goto showMenu

:configError
echo �������ݿ�������û��л����ݿ⣡
goto changeDB

:connDatabaseError
head -n 2 %DB_TEST_INFO%
echo �������ݿ�ʧ�ܣ��������û��л����ݿ⣡
goto changeDB

:end
%ONLY_KEYBOARD% echo ��������˳�...
%ONLY_KEYBOARD% pause>nul
%SUPPORT_MOUSE% choix /c /n /m "�������������˳�..."
exit
