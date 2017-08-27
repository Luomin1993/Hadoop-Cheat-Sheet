========================Install=========================
$ wget http://apache.fayea.com/sqoop/1.4.6/sqoop-1.4.6.tar.gz -P /download;tar -xvf sqoop-1.4.6.tar.gz -C /usr/lib/;mv /usr/lib/sqoop-1.4.6 /usr/lib/sqoop;
$ echo "export SQOOP_HOME=/usr/lib/sqoop" >> /etc/profile;echo "export PATH=$PATH:$SQOOP_HOME/bin" >> /etc/profile;source /etc/profile;
#配置Sqoop
$ cd $SQOOP_HOME/conf;mv sqoop-env-template.sh sqoop-env.sh;vi sqoop-env.sh;
"""
     #sqoop-env.sh
     export HADOOP_COMMON_HOME=/usr/lib/hadoop 
     export HADOOP_MAPRED_HOME=/usr/lib/hadoop   
"""
#下载并配置java的MySQL连接器
$ wget http://ftp.ntu.edu.tw/MySQL/Downloads/Connector-J/mysql-connector-java-5.1.42.tar.gz -P /download;tar -zxf mysql-connector-java-5.1.42.tar.gz;cd mysql-connector-java-5.1.42;mv mysql-connector-java-5.1.42-bin.jar /usr/lib/sqoop/lib;
$ sqoop -version

=======================Cheat Cheat========================

-------------------------------------------------------
#将数据导入HDFS:让我们以命名为emp,emp_add和emp_contact的三个表;这是一个在MySQL数据库服务器名为userdb数据库的一个例子;
$ sqoop import 
        --connect jdbc:mysql://localhost/userdb 
        --username root 
        --table emp 
        --m 1 
        --target-dir /queryresult 
        --where "city ='sec-bad'"
        --incremental append       #仅导入新添加的表中的行;
        --check-column id          #列名;
        -last value 1205           #这一行最近添加的1205个数据;

#验证在HDFS导入的数据
$ hadoop fs -cat /queryresult/part-m-*

#从USERDB数据库中导入所有的表
$ sqoop import
        --connect jdbc:mysql://localhost/userdb
        --username root
-------------------------------------------------------


-------------------------------------------------------
#如何将数据从HDFS导出到RDBMS数据库
#首先创建MySQL命令行表'employee'
$ mysql
mysql> USE userdb;
mysql> CREATE TABLE employee ( 
   id INT NOT NULL PRIMARY KEY, 
   name VARCHAR(20), 
   deg VARCHAR(20),
   salary INT,
   dept VARCHAR(10));

#用来导出表数据(这是在HDFS emp_data文件)到MySQL数据库服务器DB数据库的employee表中;
$ sqoop export 
        --connect jdbc:mysql://localhost/userdb 
        --username root 
        --table employee 
        --export-dir /emp/emp_data

---------------------------------------------------------



-------------------------------------------------------
#如何创建和维护Sqoop作业;
#创建一个名为myjob的作业,这可以从RDBMS表的数据导入到HDFS作业;
$ sqoop job 
        --create myjob
        --import 
        --connect jdbc:mysql://localhost/userdb 
        --username root 
        --table employee --m 1 

#验证保存的作业
$ sqoop job --list

#检查或验证特定的工作,及其详细信息
$ sqoop job --show myjob

#执行保存的作业
$ sqoop job --exec myjob
-------------------------------------------------------


-------------------------------------------------------
#Sqoop代码生成
#每一个数据库表具有包含“setter”和“getter”的方法来初始化DAO类对象;此工具(-codegen)自动生成DAO类;
$ sqoop codegen
        --connect jdbc:mysql://localhost/userdb
        --username root 
        --table emp

$ cd /tmp/sqoop-hadoop/compile/9a300a1f94899df4a9b10f9935ed9f91/
$ ls
     emp.class     emp.jar     emp.java       
--------------------------------------------------------


--------------------------------------------------------
#Sqoop Eval工具
#它允许用户执行用户定义的查询;对各自的数据库服务器和预览结果在控制台中;
$ sqoop eval
        --connect jdbc:mysql://localhost/db
        --username root 
        --query "SELECT * FROM employee LIMIT 3"

#插入查询计算:下面的命令用于在DB数据库的员工(employee) 表中插入新行；
$ sqoop eval 
        --connect jdbc:mysql://localhost/db
        --username root 
        -e "INSERT INTO employee VALUES(1207,'Raju','UI dev',15000,'TP')"


-------------------------------------------------------- 

--------------------------------------------------------
#使用Sqoop列出所有的数据库
$ sqoop list-databases 
        --connect jdbc:mysql://localhost/ 
        --username root

#列出MySQL数据库服务器的USERDB数据库下的所有的表
$ sqoop list-tables 
        --connect jdbc:mysql://localhost/userdb
        --username root

--------------------------------------------------------