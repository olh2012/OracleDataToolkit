::脚本功能：Oracle快速数据导出
::脚本编写：四方精创 欧林海
::版本历史：
::          2016-12-02 Ver1.1 
::                     添加数据库配置及导出格式、数据库字符集的配置
::                     添加数据库连接测试
::          2016-11-03 Ver1.0
::                     初始版本，能实现批量数据导出功能
@echo off
title Oracle数据导出命令行工具 Ver1.1 —by olh
::开启变量延迟
setlocal EnableDelayedExpansion
::切换字符编码
chcp 936>nul

::设置参数
set BIN_DIR=bin
set SQL_DIR=sql
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
for %%a in ( %SQL_DIR%\*.sql ) do (
    echo 正在导出%%~na...
    bin\sqluldr2 user=%dbEnv% sql=%%a file=%DATA_DIR%\%%~na.%exportType% text=%exportType% charset=%dbcharset%
    echo.
)

if exist %DB_TEST_RES% del %DB_TEST_RES%
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