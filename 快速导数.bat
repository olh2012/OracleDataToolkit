::脚本功能：Oracle快速数据导入与导出
::脚本编写：四方精创 欧林海
::版本历史：
::          2016-12-24 Ver1.3
::                     合并导入与导出功能，并添加菜单操作（支持鼠标点击）
::                     添加临时切换数据源功能
::                     添加目录清理功能
::          2016-12-23 Ver1.2
::                     添加数据导入功能，支持自动从csv文件中生成控制文件
::          2016-12-02 Ver1.1 
::                     添加数据库配置及导出格式、数据库字符集的配置
::                     添加数据库连接测试
::          2016-11-03 Ver1.0
::                     初始版本，能实现批量数据导出功能
@echo off
title Oracle导数命令行工具 Ver1.3 —by 欧林海
::开启变量延迟
setlocal EnableDelayedExpansion
::切换字符编码
chcp 437>nul
graftabl 936>nul

::设置参数
set CUR_DIR=%~dp0
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=数据库设置.txt
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%BIN_DIR%\test_conn.log
set path=%path%;%CUR_DIR%\%BIN_DIR%

::获取数据库配置选项
type %DB_SETTING% | findstr "^dataSource">%DB_SETTING_TMP%
for /f "delims="  %%a in ( %DB_SETTING_TMP% ) do if "%%a" neq "" set "%%a"

if not defined dataSource ( echo dataSource未配置 && goto :configError )

:setDataSource
echo =========数据库配置:%dataSource%=========

::获得配置选项字符串长度
set /a dataSourceLen=0
for /l %%i in (0,1,100) do if "!dataSource:~%%i,1!" == "" set /a dataSourceLen=%%i && goto :endfor2
:endfor2

findstr "^%dataSource%" %DB_SETTING%>%DB_SETTING_TMP%

::读取配置项
for /f "delims=@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
set fillStr=
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::检查配置项是否完整
for %%a in ( dbName exportType dbcharset dbUser dbEncPasswd dbIp dbService ) do (
    if not defined %%a echo %%a未配置，请检查！ && set checkEnvFlag=fail
)
if defined checkEnvFlag goto :configError

::设置数据库连接串
for /f "delims=" %%i in ( '%BIN_DIR%\szboc_decrypt "%dbEncPasswd%"' ) do set dbEnv=%dbUser%/%%i@%dbIp%/%dbService%

::测试数据库连接
echo 正在测试数据库连接...
if exist %DB_TEST_RES% del %DB_TEST_RES%
sqlplus -L -S %dbEnv% @%DB_TEST_SQL% %DB_TEST_RES%
if not exist %DB_TEST_RES% goto :connDatabaseError
if exist %DB_TEST_RES% findstr "success" %DB_TEST_RES% >nul || goto :connDatabaseError
echo 数据库连接成功
echo.

:showMenu
echo.
echo (1) 数据导入        
echo (2) 数据导出
echo (3) 切换数据源
echo (4) 清理目录
echo (5) 退出程序
echo --------------
echo 请选择菜单
choix /c:12345 /M( /N 

for %%a in (1 2 3 4 5) do if errorlevel %%a set item=%%a
echo 您选择了%item%
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
        echo 正在生成控制文件: !ctlFile!...
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
        echo 检测到 %%~na 对应的控制文件已存在
    )
)
echo.
echo 数据目录中总共有%fileCount%个文件，是否全部导入数据库?
echo;* Y-确定
echo;* N-取消
choix /c:YN /M- /N
if errorlevel 2 goto :showMenu

echo 开始导数...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo 正在导入!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=20000 silent=ALL direct=TRUE
    findstr /r "加载成功 没有加载" %LOG_DIR%\!fileName!.log
    echo.
)
echo 处理完成. 
goto continue

:exportData
echo 开始导数...
for %%a in ( %SQL_DIR%\*.sql ) do (
    echo 正在导出%%~na...
    sqluldr2 user=%dbEnv% sql=%%a file=%DATA_DIR%\%%~na.%exportType% text=%exportType% charset=%dbcharset%
)
echo 处理完成.
goto continue

:changeDB
findstr "@dbName" %DB_SETTING%>%DB_SETTING_TMP%
set /a seqNo=0
set seqNoText=
:showDbConfig
echo.
echo 当前已配置的数据源:
for /f "delims== tokens=2"  %%a in ( %DB_SETTING_TMP% ) do (
    set /a seqNo=seqNo+1
    set seqNoText=%seqNoText%%seqNo%
    echo;^(!seqNo!^) %%a 
)
echo ------------------
echo 请选择
choix /c:123456789 /M( /N 
set item=%errorlevel%
if %item% gtr %seqNo% echo 无效的选项,请重新输入 && goto showDbConfig
set /a item=item-1
for /f "delims=@ tokens=1 skip=%item%" %%a in ( %DB_SETTING_TMP% ) do (
    set dataSource=%%a
    goto endfor3
)
:endfor3
echo 数据源配置已切换为%dataSource%
goto setDataSource

:cleanDir
echo 请选择要清理的目录:
echo (1) 数据文件目录
echo (2) 控制文件目录
echo (3) 日志文件目录
echo (4) SQL文件目录
echo (5) 除SQL外的全部目录
echo (6) 全部目录
echo ------------------
echo 请选择
choix /c:123456 /M( /N 
set item=%errorlevel%
echo 您选择了%item%
if %item% equ 1 del /q /f %DATA_DIR%\*.*
if %item% equ 2 del /q /f %CTL_DIR%\*.*
if %item% equ 3 del /q /f %LOG_DIR%\*.*
if %item% equ 4 del /q /f %SQL_DIR%\*.*
if %item% equ 5 del /q /f %DATA_DIR%\*.* %CTL_DIR%\*.* %LOG_DIR%\*.*
if %item% equ 6 del /q /f %DATA_DIR%\*.* %CTL_DIR%\*.* %LOG_DIR%\*.* %SQL_DIR%\*.*
echo 清理完成.
goto continue


:continue
echo 按任意键返回主菜单
pause>nul
cls
goto showMenu

:end
if exist %DB_TEST_RES% del %DB_TEST_RES%
echo 按任意键退出...
pause>nul
exit

:configError
echo 请修改配置后重试！
goto continue

:connDatabaseError
echo.
echo.
echo 连接数据库失败，请检查配置！
goto continue