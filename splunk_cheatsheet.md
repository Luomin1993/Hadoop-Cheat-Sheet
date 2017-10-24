##Splunk Cheatsheet
####install
####Splunk分为服务器(Splunk)和客户端(Splunkforwarder);
####Splunk的服务器就是索引器和接收器;客户端就是数据的转发器;顾名思义就是数据可由客户端转发至server端进行索引;客户端只起到转发数据的作用;
```
[root@master]# wget -c https://download.splunk.com/products/splunk/releases/6.5.1/linux/splunk-6.5.1-f74036626f0c-Linux-x86_64.tgz; 
[root@master]# tar -zxvf splunk-6.5.1-f74036626f0c-Linux-x86_64.tgz -C /usr/lib;mv /usr/lib/splunk-* /usr/lib/splunk;
[root@master]# ./splunk start --accept-license  //启动splunk+自动接收许可
[root@master]# ./splunk restart                 //重启splunk
[root@master]# ./splunk status                  //查看splunk状态
[root@master]# ./splunk version                 //查看splunk版
[root@master]# ./splunk stop                    //停止splunk
[root@master]# ./splunk enable boot-start       //splunk服务开机启动
[root@master]# ps -f | grep splunk              //查看进程相关信息
```
splunk安装之后开启Splunk Web端口8000;Splunkd端口8089端为管理端口; 安装之后我们可以在浏览器中访问splunk 8000端口的WEB界面; 127.0.0.1:8000
如果外部计算机无法访问它;需要关闭iptables服务或将该端口加入策略中;

```
[root@master]# services iptables stop            //其它类unix系统关闭防火墙;
[root@master]# systemctl stop firewalld.service  //CentOS7下停止防火墙;

```
安装Splunk 通用转发器

```
[root@master]# tar zxvf splunkforwarder-6.4.2-00f5bb3fa822-Linux-x86_64.tgz -C /usr/lib;mv /usr/lib/splunkforwarder-* /usr/lib/splunkforwarder   //splunk转发器的安装方法和splunk一致;但它无UI界面;
[root@master]# cd /usr/lib/splunkforwarder/bin;./splunk start –accept-license //启动通用转发器;
[root@master]# ./splunk add forward-server 177.222.333.11:12345               //设置客户端的输出(发送的服务器和端口);
[root@master]# ./splunk set deploy-poll server_ip:8089                        //注册客户端到服务器;
[root@master]# ./splunk add monitor /your_dir_path                            //监控一个目录;
[root@master]# ./splunk list monitor                                          //显示有哪些被监控;
[root@master]# vi $SPLUNK_HOME/etc/system/local/input.conf                    //监控哪些目录你可以修改;
   host = 本机的hostname
   #monitor://日志地址(这里可以使用正则来过滤数据)
   index=indexName
   sourcetype=sourceName
   #monitor://另一个
   index=indexName
   sourcetype=sourceName
   #monitor:///xxx/xxx/log/xxx/xxx.log
   index=xxxxxxxx
   sourcetype=xxxxxx

[root@master]# vi $SPLUNK_HOME/etc/system/local/output.conf                   //转发数据到哪你可以修改;
[root@master]# ./splunk clean eventdata -index “test”                         //清空一个索引数据;停掉server然后运行命令;

```

splunkd的端口

```
[root@master]# ./splunk show splunkd-port      //查看splunkd的端口;得输入splunk登录的账号密码;
[root@master]# ./splunk set splunkd-port 8091  //修改splund的端口为8091;
```