
root@hanss:wget http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jdk-8u144-linux-x64.tar.gz?AuthParam=1502545143_41b9e32dd218de2ae077c06f1a077026
root@hanss:sudo mkdir /usr/lib/jdk
root@hanss:mkdir /usr/lib/jdk
root@hanss:mv jdk-8u144-linux-x64.tar.gz\?AuthParam\=1502545143_41b9e32dd218de2ae077c06f1a077026 jdk-8u144-linux-x64.tar.gz
root@hanss:tar -zxvf jdk-8u144-linux-x64.tar.gz -C /usr/lib/jdk
root@hanss:vim /etc/profile
#/etc/profile
export JAVA_HOME=/usr/lib/jdk/jdk1.8.0_144   
export JRE_HOME=${JAVA_HOME}/jre  
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
export PATH=${JAVA_HOME}/bin:$PATH
#
root@hanss:vim ~/.bashrc
#~/.bashrc
export JAVA_HOME=/usr/lib/jdk/jdk1.8.0_144
#
root@hanss:source /etc/profile
root@hanss:source ~/.bashrc

root@hanss:wget http://apache.fayea.com/hadoop/common/hadoop-2.7.4/hadoop-2.7.4.tar.gz
root@hanss:mkdir /usr/lib/hadoop
root@hanss:tar -zxvf hadoop-2.8.1.tar.gz -C /usr/lib/hadoop/
root@hanss:vim ~/.bashrc
#~/.bashrc
export PATH=$PATH:/usr/lib/hadoop/hadoop-2.7.4/bin:/usr/lib/hadoop/hadoop-2.7.4/sbin
root@hanss:vim /etc/profile
#/etc/profile
export PATH=$PATH:/usr/lib/hadoop/hadoop-2.7.4/bin:/usr/lib/hadoop/hadoop-2.7.4/sbin
#

root@hanss:vi /etc/hostname
#/etc/hostname
master
root@hanss:vi /etc/hosts
#/etc/hosts
144.122.133.12 master

root@master$: vim core-site.xml
#core-site.xml
<configuration>
        <property>
                <name>fs.defaultFS</name>
                <value>hdfs://master:9000</value>
        </property>
        <property>
                <name>hadoop.tmp.dir</name>
                <value>file:/usr/lib/hadoop-2.7.4/tmp</value>
                <description>Abase for other temporary directories.</description>
        </property>
</configuration>
root@master$: vim hdfs-site.xml
#hdfs-site.xml
<configuration>
        <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>master:50090</value>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>1</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/lib/hadoop-2.7.4/tmp/dfs/name</value>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/lib/hadoop-2.7.4/tmp/dfs/data</value>
        </property>
</configuration>
root@master$: vim mapred-site.xml
#mapred-site.xml
<configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.address</name>
                <value>master:10020</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value>master:19888</value>
        </property>
</configuration>
root@master$: vim yarn-site.xml
<configuration>
#yarn-site.xml
<!-- Site specific YARN configuration properties -->
        <property>
                <name>yarn.resourcemanager.hostname</name>
                <value>master</value>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
        </property>
</configuration>

==========================Retrying connect to server: master :8032===============
#yarn-site.xml
          <property>  
            <name>yarn.resourcemanager.address</name>  
            <value>master:8032</value>  
          </property>  
          <property>  
            <name>yarn.resourcemanager.scheduler.address</name>  
            <value>master:8030</value>  
          </property>  
          <property>  
            <name>yarn.resourcemanager.resource-tracker.address</name>  
            <value>master:8031</value>  
          </property>  
 ==========================================================


          <property>  
              <name>yarn.nodemanager.resource.memory-mb</name>  
              <value>20480</value>  
          </property>  
          <property>  
             <name>yarn.scheduler.minimum-allocation-mb</name>  
             <value>2048</value>  
          </property>  
          <property>  
              <name>yarn.nodemanager.vmem-pmem-ratio</name>  
              <value>2.1</value>  
          </property>  



  start-dfs.sh;start-yarn.sh;mr-jobhistory-daemon.sh start historyserver
  stop-dfs.sh;stop-yarn.sh;mr-jobhistory-daemon.sh stop historyserver


  ==================== maybe ==============================
  sudo systemctl stop firewalld.service


  =========================================================



  ---------------------------Pig Install-----------------------------
$ wget http://mirrors.tuna.tsinghua.edu.cn/apache/pig/pig-0.16.0/pig-0.16.0.tar.gz -P /download
$ tar -zxvf pig-0.16.0.tar.gz -C /usr/lib/
$ mv /usr/lib/pig-0.16.0 /usr/lib/pig
$ echo "export PIG_INSTALL=/usr/lib/pig" >> /etc/profile;echo "export PATH=$PATH:$PIG_INSTALL/bin" >> /etc/profile;source /etc/profile;




  ---------------------------Hive Install----------------------------
#http://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-2.3.0/apache-hive-2.3.0-bin.tar.gz  
$ wget http://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-2.3.0/apache-hive-2.3.0-bin.tar.gz -P /download
$ tar -zxvf apache-hive-2.3.0-bin.tar.gz -C /usr/lib/
$ mv /usr/lib/apache-hive-2.3.0-bin /usr/lib/hive
$ echo "export HIVE=/usr/lib/hive" >> /etc/profile;echo "export PATH=$PATH:$HIVE/bin" >> /etc/profile;source /etc/profile;








 --------------------------Pig CheatSheet----------------------------
$ ./pig -x local #Local模式
$ ./pig -x mapreduce #MapReduce模式

grunt> customers = LOAD 'customers.txt' USING PigStorage(','); #Grunt shell模式

#script模式
#Sample_script.pig
***********************************
student = LOAD 'hdfs://localhost:9000/pig_data/student.txt' USING PigStorage(',') as (id:int,name:chararray,city:chararray);
Dump student;
***********************************
$ pig -x local Sample_script.pig        
$ pig -x mapreduce Sample_script.pig

grunt> sh shell_command parameters #Grunt shell模式中执行 Linux Shell
grunt> sh ls

grunt> fs –ls                      #使用fs命令从Grunt shell调用HDFS的ls命令

grunt> exec /sample_script.pig     #exec 命令执行 sample_script.pig 中的脚本
grunt> kill JobId                  #kill 命令从Grunt shell中终止它
grunt> run /sample_script.pig      #使用run命令从Grunt shell运行上面的脚本
grunt> Dump;                       #Dump操作符查看脚本的输出

#Relation是Pig Latin数据模型的最外层结构;它是一个包,其中:
#包是元组的集合;
#元组是有序的字段集;
#字段是一段数据;



#运算符          描述

#加载和存储.........................................................
#LOAD                  将数据从文件系统（local/ HDFS）加载到关系中。(将数据加载到Apache Pig中)
$ hdfs dfs -put /home/Hadoop/Pig/Pig_Data/student_data.txt dfs://localhost:9000/pig_data/
$ pig –x mapreduce
grunt> Student_data = LOAD 'student_data.txt' USING PigStorage(',') as (id:int, firstname:chararray, lastname:chararray, phone:chararray, city:chararray );

#STORE                 将数据从文件系统（local/ HDFS）存储到关系中。
grunt> STORE student INTO ' hdfs://localhost:9000/pig_Output/ ' USING PigStorage (','); #紧接上面的加载的student,让我们将关系存储在HDFS目录“/pig_Output/"中

#过滤...............................................................
#FILTER                从关系中删除不需要的行。
grunt> filter_data = FILTER student_details BY city == 'Chennai';
grunt> Dump filter_data;

#DISTINCT              从关系中删除重复行。
grunt> distinct_data = DISTINCT student_details; #紧接上面的加载的student_details,删除其重复行;

#FOREACH，GENERATE     基于数据列生成数据转换。
grunt> foreach_data = FOREACH student_details GENERATE id,age,city;

#STREAM                使用外部程序转换关系。

#分组和连接........................................................
#JOIN                  连接两个或多个关系。
#Self-join用于将表与其自身连接;那么,将文件customers.txt的内容加载为两个表,如下所示;
grunt> customers1 = LOAD 'hdfs://localhost:9000/pig_data/customers.txt' USING PigStorage(',')
   as (id:int, name:chararray, age:int, address:chararray, salary:int);
  
grunt> customers2 = LOAD 'hdfs://localhost:9000/pig_data/customers.txt' USING PigStorage(',')
   as (id:int, name:chararray, age:int, address:chararray, salary:int); 
grunt> customers3 = JOIN customers1 BY id, customers2 BY id;

#Inner Join使用较为频繁;它也被称为等值连接;
#      JOIN relation_A BY columnname, relation_B BY columnname;
grunt> coustomer_orders = JOIN customers BY id, orders BY customer_id;

#left outer join操作返回左表中的所有行，即使右边的关系中没有匹配项。
grunt> outer_left = JOIN customers BY id LEFT OUTER, orders BY customer_id;
#right outer join操作将返回右表中的所有行，即使左表中没有匹配项。
grunt> outer_right = JOIN customers BY id RIGHT OUTER, orders BY customer_id;
#当一个关系中存在匹配时，full outer join操作将返回行。
grunt> outer_full = JOIN customers BY id FULL OUTER, orders BY customer_id;

#使用多个key对两个表执行JOIN操作。
grunt> employee = LOAD 'hdfs://localhost:9000/pig_data/employee.txt' USING PigStorage(',')
   as (id:int, firstname:chararray, lastname:chararray, age:int, designation:chararray, jobid:int);
  
grunt> employee_contact = LOAD 'hdfs://localhost:9000/pig_data/employee_contact.txt' USING PigStorage(',') 
   as (id:int, phone:chararray, email:chararray, city:chararray, jobid:int);
grunt> emp = JOIN employee BY (id,jobid), employee_contact BY (id,jobid);

#COGROUP               将数据分组为两个或多个关系。
grunt> cogroup_data = COGROUP student_details by age, employee_details by age;

#GROUP                 在单个关系中对数据进行分组。
grunt> group_data = GROUP student_details by age;

#CROSS                 创建两个或多个关系的向量积。
grunt> cross_data = CROSS customers, students;

#排序................................................................
#ORDER                 基于一个或多个字段（升序或降序）按排序排列关系。
grunt> order_by_data = ORDER student_details BY age DESC;
#LIMIT                 从关系中获取有限数量的元组。
grunt> limit_data = LIMIT student_details 4; 

#数学函数 如LOG10()
grunt> math_data = LOAD 'hdfs://localhost:9000/pig_data/math.txt' USING PigStorage(',')
   as (data:float);
grunt> log_data = foreach math_data generate (data),LOG10(data);

#Apache Pig 用户定义函数（UDF）
#       我们可以创建和使用以下三种类型的函数
#       Filter函数 - Filter（过滤）函数用作过滤器语句中的条件。这些函数接受Pig值作为输入并返回布尔值。
#       Eval函数 - Eval函数在FOREACH-GENERATE语句中使用。这些函数接受Pig值作为输入并返回Pig结果。
#       Algebraic函数 - Algebraic（代数）函数对FOREACHGENERATE语句中的内包起作用。这些函数用于对内包执行完全MapReduce操作。
"""
      import java.io.IOException; 
      import org.apache.pig.EvalFunc; 
      import org.apache.pig.data.Tuple; 
       
      import java.io.IOException; 
      import org.apache.pig.EvalFunc; 
      import org.apache.pig.data.Tuple;      

      public class Sample_Eval extends EvalFunc<String>{       

         public String exec(Tuple input) throws IOException {   
            if (input == null || input.size() == 0)      
            return null;      
            String str = (String)input.get(0);      
            return str.toUpperCase();  
         } 
      }
"""
$./pig –x local 
grunt> REGISTER '/$PIG_HOME/sample_udf.jar'
grunt> Upper_case = FOREACH emp_data GENERATE Sample_Eval(name);


 --------------------------Hive CheatSheet----------------------------