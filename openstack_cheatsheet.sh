========================Install=========================
#域名解析和关闭防火墙
$ vi /etc/hosts
"""
   #/etc/hosts
   192.168.1.17  master      
   192.168.1.8   slave1 
"""

#关闭 selinux
$ sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
$ setenforce 0

#关闭 iptables
$ systemctl start firewalld.service
$ systemctl stop firewalld.service
$ systemctl disable firewalld.service

#安装软件包
------------------------| 首先给master安装 |------------------
#Base
$ yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
$ yum install -y centos-release-openstack-liberty
$ yum install -y python-openstackclient

##MySQL
$ yum install -y mariadb mariadb-server MySQL-python

##RabbitMQ
$ yum install -y rabbitmq-server

##Keystone
$ yum install -y openstack-keystone httpd mod_wsgi memcached python-memcached

##Glance
$ yum install -y openstack-glance python-glance python-glanceclient

##Nova
$ yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

##Neutron linux-node1.example.com
$ yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge python-neutronclient ebtables ipset

##Dashboard
$ yum install -y openstack-dashboard

##Cinder
$ yum install -y openstack-cinder python-cinderclient

------------------------| 给slave1安装 |------------------
##Base
$ yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
$ yum install centos-release-openstack-liberty
$ yum install python-openstackclient

##Nova linux-node2.openstack
$ yum install -y openstack-nova-compute sysfsutils

##Neutron linux-node2.openstack
$ yum install -y openstack-neutron openstack-neutron-linuxbridge ebtables ipset

##Cinder
$ yum install -y openstack-cinder python-cinderclient targetcli python-oslo-policy


#设置时间同步,关闭 selinux和iptables 
-----------------------| 首先给master安装 |------------------
$ yum install -y chrony
$ vi /etc/chrony.conf
allow 192.168/16 #允许那些服务器和自己同步时间
$ systemctl enable chronyd.service    #开机启动
$ systemctl start chronyd.service
$ timedatectl set-timezone Asia/Shanghai     #设置时区
$ timedatectl status
Local time: Fri 2016-08-26 11:14:19 CST
Universal time: Fri 2016-08-26 03:14:19 UTC
... ...

------------------------| 给slave1安装 |------------------
$ yum install -y chrony
$ vim /etc/chrony.conf
server 192.168.1.17 iburst #只留一行
$ systemctl enable chronyd.service
$ systemctl start chronyd.service
$ timedatectl set-timezone Asia/Shanghai
$ chronyc sources


#安装及配置 mysql(他这里实际上是MariaDB)
$ cp /usr/share/mysql/my-medium.cnf /etc/my.cnf                                         #或者是/usr/share/mariadb/my-medium.cnf
$ systemctl enable mariadb.service                                                      #Centos7里面mysql叫maridb
$ ln -s '/usr/lib/systemd/system/mariadb.service' '/etc/systemd/system/multi-user.target.wants/mariadb.service'
$ mysql_install_db --datadir="/var/lib/mysql" --user="mysql"                            #初始化数据库
$ systemctl start mariadb.service
$ mysql_secure_installation                                                             #设置密码及初始化
#密码 123456，一路 y 回车
$ mysql -p 123456
Welcome to the MariaDB monitor. Commands end with ; or \g.
Your MariaDB connection id is 5579 
... ...
MariaDB [(none)]> CREATE DATABASE keystone;                                                                   #建库keystone
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';      #赋予最大权限
MariaDB [(none)]> GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone';
MariaDB [(none)]> CREATE DATABASE glance;                                                                     #建库glance
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';
MariaDB [(none)]> CREATE DATABASE nova;                                                                       #建库nova
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';
MariaDB [(none)]> CREATE DATABASE neutron;																	  #建库neutron
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';       
MariaDB [(none)]> GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';
MariaDB [(none)]> CREATE DATABASE cinder; 																	  #建库cinder
MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cinder';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cinder';
MariaDB [(none)]> flush privileges;                                                                           #刷新权限
MariaDB [(none)]> show databases;                                                                             
+--------------------+
| Database |
+--------------------+
| information_schema   |
| cinder               |
| glance               |
| keystone             |
| mysql                |
| neutron              |
| nova                 |
| performance_schema   |
+--------------------+

#启动rabbitmq,端口5672,添加openstack用户;
$ systemctl enable rabbitmq-server.service
$ ln -s '/usr/lib/systemd/system/rabbitmq-server.service' '/etc/systemd/system/multi-user.target.wants/rabbitmq-server.service'
$ systemctl start rabbitmq-server.service
$ rabbitmqctl add_user openstack openstack                               #添加用户及密码
$ rabbitmqctl set_permissions openstack ".*" ".*" ".*"                   #允许配置、写、读访问 openstack
$ rabbitmq-plugins list                                                  #查看支持的插件
... ...
rabbitmq_management 3.6.2                                                #使用此插件实现 web 管理
... ...
$ rabbitmq-plugins enable rabbitmq_management                            #启动插件
The following plugins have been enabled:
... ...
rabbitmq_management
... ...
$ systemctl restart rabbitmq-server.service
$ lsof -i:15672                                                          #访问RabbitMQ,访问地址是http://58.68.250.17:15672



#以上完成基础环境的配置,下面开始安装openstack的组件;
#配置 Keystone 验证服务
$ openssl rand -hex 10
35d6e6f377a889571bcf
$ vi /etc/keystone/keystone.conf
"""
   ... ...
   admin_token = 35d6e6f377a889571bcf                                    #设置 token，和上面产生的随机数值一致
   ... ...
"""

#创建数据库表,使用命令同步
$ su -s /bin/sh -c "keystone-manage db_sync" keystone
No handlers could be found for logger "oslo_config.cfg"                                          #出现这个信息，不影响后续操作！忽略~
$ ll /var/log/keystone/keystone.log
-rw-r--r--. 1 keystone keystone 298370 Aug 26 11:36 /var/log/keystone/keystone.log               #之所以上面 su 切换是因为这个日志文件属主
$ mysql -h 192.168.1.17 -u keystone -p                                                           #数据库检查表,生产环境密码不要用keystone，改成复杂点的密码

#启动 memcached
$ systemctl enable memcached
$ ln -s '/usr/lib/systemd/system/memcached.service' '/etc/systemd/system/multi-user.target.wants/memcached.service'
$ systemctl start memcached

#配置 httpd
$ vi /etc/httpd/conf/httpd.conf
"""
   ServerName 192.168.1.17:80
"""
$ vi /etc/httpd/conf.d/wsgi-keystone.conf
"""
   #wsgi-keystone.conf
   Listen 5000
   Listen 35357   

   <VirtualHost *:5000>
   WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
   WSGIProcessGroup keystone-public
   WSGIScriptAlias / /usr/bin/keystone-wsgi-public
   WSGIApplicationGroup %{GLOBAL}
   WSGIPassAuthorization On
   <IfVersion >= 2.4>
   ErrorLogFormat "%{cu}t %M"
   </IfVersion>
   ErrorLog /var/log/httpd/keystone-error.log
   CustomLog /var/log/httpd/keystone-access.log combined
   <Directory /usr/bin>
   <IfVersion >= 2.4>
   Require all granted
   </IfVersion>
   <IfVersion < 2.4>
   Order allow,deny
   Allow from all
   </IfVersion>
   </Directory>
   </VirtualHost>   

   <VirtualHost *:35357>
   WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
   WSGIProcessGroup keystone-admin
   WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
   WSGIApplicationGroup %{GLOBAL}
   WSGIPassAuthorization On
   <IfVersion >= 2.4>
   ErrorLogFormat "%{cu}t %M"
   </IfVersion>
   ErrorLog /var/log/httpd/keystone-error.log
   CustomLog /var/log/httpd/keystone-access.log combined
   <Directory /usr/bin>
   <IfVersion >= 2.4>
   Require all granted
   </IfVersion>
   <IfVersion < 2.4>
   Order allow,deny
   Allow from all
   </IfVersion>
   </Directory>
   </VirtualHost>
"""
#启动 httpd
$ systemctl enable httpd
$ ln -s '/usr/lib/systemd/system/httpd.service' '/etc/systemd/system/multi-user.target.wants/httpd.service'
$ systemctl start httpd
$ netstat -lntup|grep httpd
tcp6 0 0 :::5000 :::* LISTEN 23632/httpd
tcp6 0 0 :::80 :::* LISTEN 23632/httpd
tcp6 0 0 :::35357 :::* LISTEN 23632/httpd

#创建keystone用户
#临时设置 admin_token 用户的环境变量,用来创建用户
$ export OS_TOKEN=35d6e6f377a889571bcf                 #上面产生的随机数值
$ export OS_URL=http://192.168.1.17:35357/v3
$ export OS_IDENTITY_API_VERSION=3

$ openstack project create --domain default --description "Admin Project" admin   #创建admin项目
$ openstack user create --domain default --password-prompt admin                  #创建admin用户
$ openstack role create admin                                                     #创建admin角色
$ openstack role add --project admin --user admin admin                           #把admin用户加入到admin项目赋予admin的角色

#创建一个普通用户demo,操作同上
$ openstack project create --domain default --description "Demo Project" demo
$ openstack user create --domain default --password=demo demo
$ openstack role create user
$ openstack role add --project demo --user demo user

#创建service项目,用来管理其他服务用
$ openstack project create --domain default --description "Service Project" service
$ openstack user list
+----------------------------------+-------+
| ID | Name |
+----------------------------------+-------+
| b1f164577a2d43b9a6393527f38e3f75 | demo |
| b694d8f0b70b41d883665f9524c77766 | admin |
+----------------------------------+-------+

$ openstack project list
+----------------------------------+---------+
| ID | Name |
+----------------------------------+---------+
| 604f9f78853847ac9ea3c31f2c7f677d | demo |
| 777f4f0108b1476eabc11e00dccaea9f | admin |
| aa087f62f1d44676834d43d0d902d473 | service |
+----------------------------------+---------+

#注册 keystone 服务，以下三种类型分别为公共的、内部的、管理的。
$ openstack service create --name keystone --description "OpenStack Identity" identity
$ openstack endpoint create --region RegionOne identity public http://192.168.1.17:5000/v2.0
$ openstack endpoint create --region RegionOne identity internal http://192.168.1.17:5000/v2.0
$ openstack endpoint create --region RegionOne identity admin http://192.168.1.17:35357/v2.0
$ openstack endpoint list #查看
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------+
| ID        |                          Region | Service Name | Service Type | Enabled |Interface | URL |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------+
| 011a24def8664506985815e0ed2f8fa5 | RegionOne | keystone | identity | True |internal | http://192.168.1.17:5000/v2.0 |
| b0981cae6a8c4b3186edef818733fec6 | RegionOne | keystone | identity | True | public  | http://192.168.1.17:5000/v2.0 |
| c4e0c79c0a8142eda4d9653064563991 | RegionOne | keystone | identity | True | admin   | http://192.168.1.17:35357/v2.0|
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------------+
$ openstack endpoint delete ID     #使用这个命令删除某ID

#验证,获取token,只有获取到才能说明keystone配置成功
$ unset OS_TOKEN
$ unset OS_URL       #unset:清除该环境变量
$ openstack --os-auth-url http://192.168.1.17:35357/v3 
            --os-project-domain-id default 
            --os-user-domain-id default 
            --os-project-name admin 
            --os-username admin 
            --os-auth-type password token issue      
            #回车
Password: admin      #Password为提示符,输入admin;
+------------+----------------------------------+
| Field | Value |
+------------+----------------------------------+
| expires | 2015-12-17T04:22:00.600668Z         |
| id | 1b530a078b874438aadb77af11ce297e         |
| project_id | 777f4f0108b1476eabc11e00dccaea9f |
| user_id | b694d8f0b70b41d883665f9524c77766    |
+------------+----------------------------------+


#创建两个环境变量文件,用时直接source!!!
$ vi admin-openrc.sh 
"""
   export OS_PROJECT_DOMAIN_ID=default
   export OS_USER_DOMAIN_ID=default
   export OS_PROJECT_NAME=admin
   export OS_TENANT_NAME=admin
   export OS_USERNAME=admin
   export OS_PASSWORD=admin
   export OS_AUTH_URL=http://192.168.1.17:35357/v3
   export OS_IDENTITY_API_VERSION=3
"""
$ vi demo-openrc.sh
"""
   export OS_PROJECT_DOMAIN_ID=default
   export OS_USER_DOMAIN_ID=default
   export OS_PROJECT_NAME=demo
   export OS_TENANT_NAME=demo
   export OS_USERNAME=demo
   export OS_PASSWORD=demo
   export OS_AUTH_URL=http://192.168.1.17:5000/v3
   export OS_IDENTITY_API_VERSION=3
"""
$ source admin-openrc.sh
$ openstack token issue
+------------+----------------------------------+
| Field | Value |
+------------+----------------------------------+
| expires | 2015-12-17T04:26:08.625399Z |
| id      | 58370ae3b9bb4c07a67700dd184ad3b1 |
16
| project_id | 777f4f0108b1476eabc11e00dccaea9f |
| user_id    | b694d8f0b70b41d883665f9524c77766 |
+------------+----------------------------------+

#配置 glance 镜像服务
#端口：
#api            9191
#registry       9292
$ vi /etc/glance/glance-api.conf 
"""
   [DEFAULT]
   verbose=True
   notification_driver = noop                                           #galnce 不需要消息队列
   [database]
   connection=mysql://glance:glance@192.168.1.17/glance
   [glance_store]
   default_store=file
   filesystem_store_datadir=/var/lib/glance/images/
   [image_format]
   [keystone_authtoken]
   auth_uri = http://192.168.1.17:5000
   auth_url = http://192.168.1.17:35357
   auth_plugin = password
   project_domain_id = default
   user_domain_id = default
   project_name = service
   username = glance
   password = glance
   [matchmaker_redis]
   [matchmaker_ring]
   [oslo_concurrency]
   [oslo_messaging_amqp]
   [oslo_messaging_qpid]
   [oslo_messaging_rabbit]
   [oslo_policy]
   [paste_deploy]
   flavor=keystone
   [store_type_location_strategy]
   [task]
   [taskflow_executor]
"""
$ vi /etc/glance/glance-registry.conf
"""
   [DEFAULT]
   verbose=True
   notification_driver = noop
   [database]
   connection=mysql://glance:glance@192.168.1.17/glance
   [glance_store]
   [keystone_authtoken]
   auth_uri = http://192.168.1.17:5000
   auth_url = http://192.168.1.17:35357
   auth_plugin = password
   project_domain_id = default
   user_domain_id = default
   project_name = service
   username = glance
   password = glance
   [matchmaker_redis]
   [matchmaker_ring]
   [oslo_messaging_amqp]
   [oslo_messaging_qpid]
   [oslo_messaging_rabbit]
   [oslo_policy]
   [paste_deploy]
   flavor=keystone
"""


#创建数据库表，同步数据库
$ su -s /bin/sh -c "glance-manage db_sync" glance
$ mysql -h 192.168.1.17 -uglance -p

#创建关于 glance 的 keystone 用户
$ source admin-openrc.sh     #admin-openrc.sh是已配置的环境变量
$ openstack user create --domain default --password=glance glance
$ openstack role add    --project service --user glance admin

#启动 glance
$ systemctl enable openstack-glance-api
$ systemctl enable openstack-glance-registry
$ systemctl start openstack-glance-api
$ systemctl start openstack-glance-registry
$ netstat -lnutp |grep 9191 #registry
tcp 0 0 0.0.0.0:9191 0.0.0.0:* LISTEN 24890/python2
$ netstat -lnutp |grep 9292 #api
tcp 0 0 0.0.0.0:9292 0.0.0.0:* LISTEN 24877/python2

#在 keystone 上注册
$ source admin-openrc.sh
$ openstack service  create --name   glance --description "OpenStack Image service" image
$ openstack endpoint create --region RegionOne image public http://192.168.1.17:9292
$ openstack endpoint create --region RegionOne image internal http://192.168.1.17:9292
$ openstack endpoint create --region RegionOne image admin http://192.168.1.17:9292

#添加 glance 环境变量并测试
$ echo "export OS_IMAGE_API_VERSION=2" | tee -a admin-openrc.sh demo-openrc.sh
$ glance image-list
+----+------+
| ID | Name |
+----+------+
+----+------+

#下载镜像并上传到 glance
$ wget -q http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img                                   #也可以提前下载下来
$ glance image-create --name "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress
[=============================>] 100%
+------------------+--------------------------------------+
| Property | Value |
+------------------+--------------------------------------+
| checksum | ee1eca47dc88f4879d8a229cc70a07c6 |
| container_format | bare |
| created_at | 2015-12-17T04:11:02Z |
| disk_format | qcow2 |
| id | 2707a30b-853f-4d04-861d-e05b0f1855c8 |
| min_disk | 0 |
| min_ram | 0 |
| name | cirros |
| owner | 777f4f0108b1476eabc11e00dccaea9f |
| protected | False |
| size | 13287936 |
| status | active |
| tags | [] |
| updated_at | 2015-12-17T04:11:03Z |
| virtual_size | None |
| visibility | public |
+------------------+--------------------------------------+


$ glance image-list
+--------------------------------------+--------+
| ID | Name |
+--------------------------------------+--------+
| 2707a30b-853f-4d04-861d-e05b0f1855c8 | cirros |
+--------------------------------------+--------+

$ ll /var/lib/glance/images/                            #实际存储位置
总用量 12980
-rw-r-----. 1 glance glance 1569390592 Aug 26 12:50 35b36f08-eeb9-4a91-9366-561f0a308a1b



=======================Cheat Cheat========================