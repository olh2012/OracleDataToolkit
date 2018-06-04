# Oracle快速导数工具

Oracle快速导数工具，用于从Oracle数据库导出表数据或将表数据导入Oracle，使用集中配置管理数据源，简化了原来的导入导出繁琐步骤，特别适合数据量比较大的情况。

## 背景说明

在工作中，大部分应用的后台数据库均采用Oracle，在平时的开发、测试及运维当中，经常涉及数据的导入导出操作，当数据量不大时，采用直接执行SQL语句的方式，当时涉及大量数据时，推荐使用 `sqlldr`（导入）和`sqluldr2`（导出）。但是在使用过程中仍然有不方便的地方，比如执行导入时，需要准备CTL文件，同时还需要准备好执行的命令行脚本，还存在脚本中暴露数据库密码明文的问题，不符合安全规定，为此，本人开发了基于Oracle的数据快速导入导出工具。

## 目录说明

```text
├───bin    命令行工具目录
├───ctl    控制文件目录（导入）
├───data   数据文件目录（导入、导出共用）
├───log    日志文件目录（导入）
└───sql    SQL文件目录（导出）
```

## 数据库选择

1. 编辑 数据库设置.txt，可以修改数据库的相关配置，修改dataSource选项可切换当前活动的数据库；
2. 在程序执行界面选择 切换数据库 会临时将数据库切换到另外的配置，但是不会把修改保存到 数据库设置.ini，在选择界面中只显示前面9个数据库（超过请直接修改配置文件）；
3. 在打开程序或执行切换数据库操作之后，会自动进行数据库连接测试；如果连接失败，可以修改配置后再重新选择数据库。

## 数据导出

1. 表数据的原样导出，可以直接在sql目录中的table_list.txt文件中添加表名（可以在表名之后添加条件），多个表名以换行分隔；
2. 通过SQL查询语句的数据导出，将导数SQL文件放到sql目录中；
3. 双击执行 快速导数.bat，选择 导出数据 菜单，等程序执行完毕之后可在data目录可以看到相应的数据文件；
4. 表清单中导出的数据，文件名与表名一致；SQL文件导出的数据，主文件名与SQL文件一致。

## 数据导入

1. 将数据文件放到数据文件目录下，目前程序限定仅导入扩展名为CSV、TXT的文件；
2. 打开 数据库设置.ini 选择装载模式，取值有 Insert(要求表为空)、Append(追加方式)、Replace(替换旧记录)、Truncate(装载前截断表)；
3. 双击执行 快速导数.bat，选择 导入数据 菜单；
4. 如果文件类型为CSV文件且控制文件不存在，程序会根据数据文件自动生成控制文件；
5. 如果是其他类型的文件，请先准备好控制文件，否则导入时会提示控制文件不存在并跳过；
6. sqlldr默认的列长度最大不超过256字节，如果超过此限制要在CTL文件中指明具体长度，如 ADD_DATA CHAR(4000) 注意不能用VARCHAR；
7. 在生产环境执行导入时，需输入YES（全部大写）以确认该操作；
8. 在执行导入时，文件类型为CSV的将跳过首行，而TXT类型的跳过的行数为0；
9. 文件导入完毕会有结果提示；
10. 执行完大数据量的导入操作后，建议执行统计信息分析，参考语句：

```SQL
dbms_stats.gather_table_stats(ownname => '模式名',tabname => '表名', cascade => TRUE,estimate_percent => 10)
```

## 查看结果：

1. 程序执行过程中会在屏幕输出关键提示信息；
2. 要查看详细的日志信息可直接打开日志目录中相应的文件查看。

## 其他说明：

1. 程序界面中的各个菜单选择或选项确定可以使用鼠标左键点击（仅32位系统），也可以使用提示的键盘按键；
2. 数据库密码配置项为dbPassword(明文），但强烈建议用加密的密码配置项dbEncPassword（加密方式：BASE64）；
3. 如果电脑中没有其他可进行BASE64加密的工具，可以使用系统自带的命令行实现：

```batch
certutil -encode password.txt password.out
```

其中password.txt文件存储了密码明文，password.out是一个用于存储密文的文件，如果原来这个文件存在请先删除。

frank
建议或Bug反馈： franka907@126.com
