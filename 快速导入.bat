::脚本功能：Oracle快速数据导入
::脚本编写：四方精创 欧林海
::版本历史：
::          2016-12-22 Ver1.0
::                     初始版本，支持批量数据导入功能（CSV格式）
@echo off
title Oracle数据导入命令行工具 Ver1.0 —by olh
::开启变量延迟
setlocal EnableDelayedExpansion
::切换字符编码
chcp 936>nul

::设置参数
set BIN_DIR=bin
set SQL_DIR=sql
set CTL_DIR=ctl
set DATA_DIR=data
set LOG_DIR=log
set DB_SETTING=数据库设置.txt
set DB_SETTING_TMP=%BIN_DIR%\dataSource.cfg
set DB_TEST_SQL=%BIN_DIR%\test_conn.sql
set DB_TEST_RES=%BIN_DIR%\test_conn.log

::获取数据库配置选项
type %DB_SETTING% | findstr "^dataSource">%DB_SETTING_TMP% 
for /f "delims="  %%a in ( %DB_SETTING_TMP% ) do if "%%a" neq "" set "%%a"
if not defined dataSource ( echo dataSource未配置 && goto :configError )

echo ========dataSource:%dataSource%========

::获得配置选项字符串长度
for /l %%i in (0,1,100) do if "!dataSource:~%%i,1!" == "" set /a dataSourceLen=%%i && goto :endfor2
:endfor2

type %DB_SETTING% | findstr "^%dataSource%">%DB_SETTING_TMP%

::读取配置项
for /f "delims=@ tokens=2"  %%a in ( %DB_SETTING_TMP% ) do set "%%a" && echo %%a

set /a fillStrLen=%dataSourceLen%+30
for /l %%i in (0,1,%fillStrLen%) do set fillStr=!fillStr!=
echo %fillStr%

::检查配置项是否完整
for %%a in ( dbName exportType dbcharset dbUser dbEncPasswd dbIp dbService ) do (
    if not defined %%a echo %%a未配置，请检查！ && set checkEnvFlag=fail
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
set /p needImport=是否将%DATA_DIR%目录中的%fileCount%个数据文件导入数据库(y-是，其他-否):
if not "x%needImport%" == "xy" goto :end
echo.
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

echo 开始导数...
for %%a in ( %DATA_DIR%\*.csv ) do (
    set fileName=%%~na
    echo 正在导入!fileName!...
    sqlldr %dbEnv% control=%CTL_DIR%\!fileName!.ctl data=%DATA_DIR%\!fileName!.csv bad=%DATA_DIR%\!fileName!.bad log=%LOG_DIR%\!fileName!.log skip=1 rows=20000 silent=ALL direct=TRUE
    findstr /r "加载成功 没有加载" %LOG_DIR%\!fileName!.log
    echo.
)



if exist %DB_TEST_RES% del %DB_TEST_RES%

:end
echo 处理完成,按任意键退出...
pause>nul
exit

:configError
echo 请修改配置后重试！
echo 程序中止,按任意键退出...
pause>nul
exit

:connDatabaseError
echo.
echo.
echo 连接数据库失败，请检查配置！
echo 程序中止,按任意键退出...
pause>nul
exit