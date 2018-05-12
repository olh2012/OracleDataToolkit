::脚本功能：Oracle快速数据导入与导出
::脚本编写：四方精创 欧林海
::版本历史：
::          2018-05-11 Ver2.0
::                       将加解密方案切换为BASE64
::          2018-04-24 Ver1.9
::                       为生产环境的表数据导入添加额外的确认操作
::          2017-09-16 Ver1.8
::                       将数据库配置文件名修改为INI格式
::                       解决了CSV文件中的列名总长度超过1024字节时生成的CTL文件列丢失的问题
::                       新增导入配置项importMode，用于指定执行sqlldr时使用的装载方式
::                       增加配置选项的默认值设置，包含exportType、importMode、fieldSeperator、recordSeperator、dbCharset、dbHostPort
::          2017-09-12 Ver1.7
::                       将加解密的程序版本更新到2.2
::                       配置项的分隔符修改为"@@"，如果值域包含@@，请使用^@^@
::          2017-04-08 Ver1.6
::                       添加64位操作系统支持，添加是否启用鼠标操作的配置（仅32位系统有效）
::                       将导入数据文件的格式限定为csv，txt
::          2017-03-30 Ver1.5
::                       解决配置未重置的问题
::                       添加了数据库密码明文配置项dbPassword（原来仅支持密文配置项dbEncPassword）
::          2016-12-26 Ver1.4
::                       添加直接按照数据库表清单导出数据功能
::                       添加数据库端口配置项dbHostPort
::                       添加导出数据字段分隔符设置fieldSeperator
::                       添加导出数据记录分隔符设置recordSeperator
::          2016-12-24 Ver1.3
::                       合并导入与导出功能，并添加菜单操作（支持鼠标点击）
::                       添加临时切换数据库功能
::                       添加目录清理功能
::          2016-12-23 Ver1.2
::                       添加数据导入功能，支持自动从csv文件中生成控制文件
::          2016-12-02 Ver1.1 
::                       添加数据库配置及导出格式、数据库字符集的配置
::                       添加数据库连接测试
@echo off
::开启变量延迟
setlocal EnableDelayedExpansion

::设置32位系统或64位系统执行标识
if /i "%PROCESSOR_IDENTIFIER:~0,3%"=="x86" (
    set "WIN_BIT=Win32" 
    set "ONLY_X64=REM"
) else (
    set "WIN_BIT=Win64" 
    set "ONLY_X86=REM"
)

title Oracle快速导数工具 Ver2.0(%WIN_BIT%) —by 欧林海

::切换字符编码
%ONLY_X64% chcp 936>nul
%ONLY_X86% chcp 437>nul
%ONLY_X86% graftabl 936>nul
::调整字体颜色
color 0a

::设置参数
set CUR_DIR=%~dp0
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=数据库设置.ini
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_PWD_TMP=%BIN_DIR%\dbPwd
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%LOG_DIR%\test_conn_res.log
set DB_TEST_INFO=%LOG_DIR%\test_conn_info.log
set path=%path%;%CUR_DIR%\%BIN_DIR%
set TAB_LIST=%SQL_DIR%\table_list.txt
set CHOICE_TIPS=请选择菜单

::执行环境检查
::检查Oracle命令行工具是否可用
for %%a in ( sqlplus.exe sqlldr.exe ) do (
    where %%a 1>nul 2>nul || ( echo Oracle命令行 %%a 未找到，请确认本机是否安装了带命令行工具的Oracle. && goto end )
)

::检查BIN目录中的可执行文件是否缺失
for %%a in ( sqluldr2.exe head.exe choix.com ) do (
    if not exist %BIN_DIR%\%%a echo 缺少程序必需的文件: %BIN_DIR%\%%a && goto end
)

::目录初始化
for %%a in ( %SQL_DIR% %CTL_DIR% %DATA_DIR% %LOG_DIR% ) do if not exist %%a md %%a

::获取数据库配置选项
type %DB_SETTING% | findstr "^dataSource ^mouseEnable">%DB_SETTING_TMP%
for /f "delims= "  %%a in ( %DB_SETTING_TMP% ) do if "x%%a" neq "x" set "%%a"

if not defined dataSource ( echo dataSource未配置 && goto configError )
::鼠标操作设置,64位兼容模式不支持鼠标
set "ONLY_KEYBOARD="
set "SUPPORT_MOUSE=REM"
%ONLY_X86% if /i "%mouseEnable%" == "true" ( set "ONLY_KEYBOARD=REM" && set "SUPPORT_MOUSE=" )
%SUPPORT_MOUSE% set CHOICE_TIPS=%CHOICE_TIPS%(支持鼠标点击)

:setDataSource
echo ==========数据库配置:%dataSource%==========

::获得配置选项字符串长度
set /a dataSourceLen=0
for /l %%i in (0,1,100) do if "x!dataSource:~%%i,1!" == "x" set /a dataSourceLen=%%i && goto endfor2
:endfor2

::重置配置项
for %%a in ( dbName exportType importMode fieldSeperator recordSeperator dbCharset dbUser dbPassword dbEncPassword dbHostIp dbHostPort dbService ) do set %%a=

findstr "^%dataSource%" %DB_SETTING%>%DB_SETTING_TMP%

::读取配置项
for /f "delims=@@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
set fillStr=
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::检查配置项是否完整
for %%a in ( dbName dbUser dbHostIp dbService ) do (
    if not defined %%a echo %%a未配置，请检查！ && set checkEnvFlag=fail
)
if not defined dbPassword if not defined dbEncPassword echo 数据库密码未设置! && set checkEnvFlag=fail
if defined checkEnvFlag goto configError

::设置配置项默认值
if not defined exportType set exportType=csv
if not defined importMode set importMode=Append
if not defined fieldSeperator set fieldSeperator=,
if not defined recordSeperator set recordSeperator=0x0a
if not defined dbCharset set dbCharset=gbk
if not defined dbHostPort set dbHostPort=1521

::设置数据库连接串
set passwordStr=
if defined dbEncPassword (
    echo %dbEncPassword%>%DB_PWD_TMP%.tmp
    if exist %DB_PWD_TMP%.out del %DB_PWD_TMP%.out
    certutil -decode %DB_PWD_TMP%.tmp %DB_PWD_TMP%.out>nul
    for /f %%i in ( %DB_PWD_TMP%.out ) do (
        if "x%%i" == "x" echo 数据库密码无法解析 && goto configError
        set passwordStr=%%i
    )
    if exist %DB_PWD_TMP%.* del %DB_PWD_TMP%.*
) else (
    set passwordStr=%dbPassword%
)
set dbEnv=%dbUser%/%passwordStr%@%dbHostIp%:%dbHostPort%/%dbService%

::测试数据库连接
echo 数据库连接验证中...
if exist %DB_TEST_RES% del %DB_TEST_RES%
sqlplus -L -S %dbEnv% @%DB_TEST_SQL% %DB_TEST_RES%>%DB_TEST_INFO%
findstr "success" %DB_TEST_RES% 1>nul 2>nul && echo 数据库连接成功 || goto connDatabaseError

:showMenu
echo.
echo   (1) 导入数据
echo   (2) 导出数据
echo   (3) 切换数据库
echo   (4) 清理目录
echo   (5) 退出程序
echo ------------------------
%ONLY_KEYBOARD% choice /c:12345 /n /m "%CHOICE_TIPS%"
%SUPPORT_MOUSE% choix /c:12345 /n /m( "%CHOICE_TIPS%"

set item=%errorlevel%
if %item% equ 5 exit
%SUPPORT_MOUSE% echo 您选择了%item%
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
            echo !fileCount!.数据文件：%%a
            echo   正在生成控制文件: !ctlFile!...
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
            echo !fileCount!.数据文件：%%a
            echo   已经存在的控制文件: !ctlFile!
        )
    ) else (
        if not exist !ctlFile! (
            echo 数据文件 %%a 缺少对应的控制文件，将被忽略.
            set /a fileCount=!fileCount!-1
        ) else (
            echo !fileCount!.数据文件：%%a
            echo   已经存在的控制文件: !ctlFile!
        )
    )
)
echo.
if %fileCount% equ 0 echo 没有要导入的数据文件 && goto continue
echo 要将这%fileCount%个文件导入【%dbName%】吗?
echo; * Y-确定
echo; * N-取消
%ONLY_KEYBOARD% choice /c:YN /n
%SUPPORT_MOUSE% choix /c:YN /n /m*
if errorlevel 2 echo 您选择了N && goto showMenu
echo 您选择了Y
::确认是否为生产环境
set confirmStr=
set localIp=
for /f "tokens=4" %%a in ('route print^|findstr 0.0.0.0.*0.0.0.0') do set localIp=%%a
if "x%localIp:~0,6%" == "x10.100" (
    set /p confirmStr=当前为生产环境，请输入YES确认入库:
    if not "x!confirmStr!" == "xYES" echo 您取消了本次操作 && goto continue
)

echo.
echo 导入数据开始...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo 正在导入!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=200000 silent=HEADER direct=TRUE
    findstr /r "加载成功 没有加载" %LOG_DIR%\!fileName!.log
    echo.
)
for %%a in ( %DATA_DIR%\*.txt ) do (
    set fileName=%%~na
    set fileExtName=%%~xa
    if exist %CTL_DIR%\!fileName!.ctl (
        echo 正在导入!fileName!...
        sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!!fileExtName! bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=0 rows=20000 silent=HEADER direct=TRUE
        findstr /r "加载成功 没有加载" %LOG_DIR%\!fileName!.log
        echo.
    )
)
echo 导入数据结束. 
goto continue

:exportData
echo 导出数据开始...
if exist %TAB_LIST% (
    echo 执行表清单的数据导出...
    for /f "eol=# delims=" %%a in ( %TAB_LIST% ) do (
        if "x%%a" neq "x" (
            for /f "delims= " %%i in ( "%%a" ) do set dataFileName=%%i
            echo 正在导出 !dataFileName!...
            sqluldr2 user=%dbEnv% query="select * from %%a" file=%DATA_DIR%\!dataFileName!.%exportType% text=%exportType% charset=%dbCharset% field="%fieldSeperator%" record="%recordSeperator%" rows=500000
        )
    )
)
echo.
if exist %SQL_DIR%\*.sql echo 执行SQL文件的数据导出...
for %%a in ( %SQL_DIR%\*.sql ) do (
    echo 正在导出 %%~na...
    sqluldr2 user=%dbEnv% sql=%%a file=%DATA_DIR%\%%~na.%exportType% text=%exportType% charset=%dbCharset% field="%fieldSeperator%"  record="%recordSeperator%" rows=500000
)
echo 导出数据结束.
goto continue

:changeDB
echo 数据库列表>%DB_SETTING_TMP%
findstr "@@dbName" %DB_SETTING%>>%DB_SETTING_TMP%
set /a seqNo=0
set seqNoText=
echo.
echo 当前已配置的数据库:
for /f "delims== tokens=2"  %%a in ( %DB_SETTING_TMP% ) do (
    set /a seqNo=seqNo+1
    set seqNoText=%seqNoText%%seqNo%
    echo;  ^(!seqNo!^) %%a
    if !seqNo! equ 9 goto endfor4
)
:endfor4
echo ------------------------
%ONLY_KEYBOARD% choice /c:123456789 /n /m "请选择"
%SUPPORT_MOUSE% choix /c:123456789 /n /m( "请选择"
set item=%errorlevel%
%SUPPORT_MOUSE% echo 您选择了%item%
if %item% gtr %seqNo% echo 无效的选项,请重新输入 && goto changeDB
for /f "delims=@@ tokens=1 skip=%item%" %%a in ( %DB_SETTING_TMP% ) do (
    set dataSource=%%a
    goto endfor3
)
:endfor3
echo 数据库配置已切换为%dataSource%
goto setDataSource

:cleanDir
echo 请选择要清理的目录:
echo   (1) 数据文件目录
echo   (2) 控制文件目录
echo   (3) 日志文件目录
echo   (4) SQL文件目录
echo   (5) 除SQL外的全部目录
echo   (6) 全部目录
echo   (7) 取消清理
echo ------------------------
%ONLY_KEYBOARD% choice /c:1234567 /n /m "请选择"
%SUPPORT_MOUSE% choix /c:1234567 /n /m( "请选择"
set item=%errorlevel%
%SUPPORT_MOUSE% echo 您选择了%item%
if %item% equ 1 call :cleanDir %DATA_DIR%\*.*
if %item% equ 2 call :cleanDir %CTL_DIR%\*.ctl
if %item% equ 3 call :cleanDir %LOG_DIR%\*.log
if %item% equ 4 call :cleanDir %SQL_DIR%\*.sql
if %item% equ 5 for %%a in (%DATA_DIR%\*.* %CTL_DIR%\*.ctl %LOG_DIR%\*.log) do call :cleanDir %%a
if %item% equ 6 for %%a in (%DATA_DIR%\*.* %CTL_DIR%\*.ctl %LOG_DIR%\*.log %SQL_DIR%\*.sql) do call :cleanDir %%a
if %item% neq 7 echo 清理完成.
goto continue

:cleanDir
if "x%1" neq "x" (
    if exist "%1" del /q /f /s "%1"
)
goto :EOF


:continue
%SUPPORT_MOUSE% choix /c /n /m "点击鼠标或按任意键返回主菜单..."
%ONLY_KEYBOARD% echo 按任意键返回主菜单...
%ONLY_KEYBOARD% pause>nul
cls
goto showMenu

:configError
echo 请检查数据库参数配置或切换数据库！
goto changeDB

:connDatabaseError
head -n 2 %DB_TEST_INFO%
echo 连接数据库失败，请检查配置或切换数据库！
goto changeDB

:end
%ONLY_KEYBOARD% echo 按任意键退出...
%ONLY_KEYBOARD% pause>nul
%SUPPORT_MOUSE% choix /c /n /m "点击鼠标或按任意键退出..."
exit
