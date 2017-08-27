=============================Install================================
#下载解压安装Zookeeper包(storm通过zookeeper来协调整个集群)
$ wget http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.9/zookeeper-3.4.9.tar.gz -P /download;tar -xvf zookeeper-3.4.9.tar.gz -C /usr/lib/;mv /usr/lib/zookeeper-3.4.9 /usr/lib/zookeeper;
$ echo "export ZOOKEEPER_HOME=/usr/lib/zookeeper" >> /etc/profile;echo "export PATH=$PATH:$ZOOKEEPER_HOME/bin" >> /etc/profile;source /etc/profile;
$ cd $ZOOKEEPER_HOME/conf;vi zoo.cfg;
"""
   #zoo.cfg
   tickTime=2000  
   dataDir=/usr/lib/zookeeper/data  
   dataLogDir=/usr/lib/zookeeper/logs  
   clientPort=4180 
"""
$ vi zoo1.cfg 
"""
   #zoo1.cfg
   tickTime=2000
   clientPort=2181 
   initLimit=5
   syncLimit=2
   dataDir=/usr/lib/zookeeperdata/1 
   server.1=localhost:2888:3888
   server.2=localhost:2889:3889
   server.3=localhost:2890:3890
"""
$ bin/zkServer.sh start ./conf/zoo1.cfg  #启动ZooKeeper(以zoo1的配置);
$ bin/zkServer.sh status zoo1.cfg        #查看状态;

$ java -cp zookeeper.jar:lib/log4j-1.2.15.jar:conf org.apache.zookeeper.server.quorum.QuorumPeerMain zoo.cfg #通过java启动zookeeper;

#安装storm依赖库:ZMQ、JZMQ;

---------------|  ZMQ Install   |---------------
$ sudo yum install unzip
$ sudo yum install e2fsprogsl  -b current
$ sudo yum install e2fsprogs-devel  -b current
$ wget http://download.zeromq.org/zeromq-2.1.7.tar.gz
$ tar -xzf zeromq-2.1.7.tar.gz
$ cd zeromq-2.1.7
$ ./configure
$ make
$ sudo make install
------------------------------------------------


--------------|  JZMQ Install   |--------------
$ git clone https://github.com/nathanmarz/jzmq.git
$ cd jzmq
$ ./autogen.sh
$ ./configure
$ make
$ sudo make install
------------------------------------------------

--------------|  storm Install   |--------------
$ wget https://github.com/downloads/nathanmarz/storm/storm-0.8.1.zip -P /download;unzip storm-0.8.1.zip -d /usr/lib;mv /usr/lib/storm-0.8.1 /usr/lib/storm;
$ echo "export STORM_HOME=/usr/lib/storm" >> /etc/profile;echo "export PATH=$PATH:$STORM_HOME/bin" >> /etc/profile;source /etc/profile;
$ ./storm version
$ vi $STORM_HOME/conf/storm.yaml #
"""
   #storm.yaml
   storm.zookeeper.servers:
   - "111.222.333.444"
   - "555.666.777.888"                                                #Storm集群使用的Zookeeper集群地址;

   storm.local.dir: "/home/admin/storm/workdir"                       #Nimbus和Supervisor进程用于存储少量状态,如jars、confs的本地磁盘目录;

   java.library.path: "/usr/local/lib:/opt/local/lib:/usr/lib"        #Storm使用的本地库(ZMQ和JZMQ)加载路径;

   nimbus.host: "111.222.333.444"                                     #Storm集群Nimbus机器地址;

   supervisor.slots.ports:
    - 6700
    - 6701
    - 6702
    - 6703                                                            #该配置选项即用于定义哪些端口是可被worker使用的;
"""

#启动Storm各个后台进程
#启动Nimbus后台程序,并放到后台执行；;
$ storm nimbus >/dev/null 2>&1 &

#启动Supervisor后台程序,并放到后台执行;
$ storm supervisor >/dev/null 2>&1 &

#启动UI后台程序,并放到后台执行,启动后可以通过http://{nimbus host}:8080观察集群的worker资源使用情况、Topologies的运行状态等信息;
$ storm ui >/dev/null 2>&1 &

#向集群提交任务
#启动Storm Topology
$ storm jar allmycode.jar org.me.MyTopology TopoName

#停止Storm Topology
$ storm kill TopoName

#激活运行指定名拓扑的所有spout
$ storm activate topology-name

#对正在运行的拓扑的工作进程(worker)进行弹性扩展;-w是等待时间;
$ storm rebalance topology-name -w 24
-----------------------------------------------



============================= Cheat Cheat ==================================
#一个word-count拓扑示例
"""
   TopologyBuilder builder = new TopologyBuilder();
   builder.setSpout("sentences", new KestrelSpout("kestrel.backtype.com",
                                                   22133,
                                                   "sentence_queue",
                                                   new StringScheme()));
   builder.setBolt("split", new SplitSentence(), 10)
          .shuffleGrouping("sentences");
   builder.setBolt("count", new WordCount(), 20)
          .fieldsGrouping("split", new Fields("word"));
"""

#使用Maven构建Storm应用
"""
   #pom.xml
   <dependency>
     <groupId>org.apache.storm</groupId>
     <artifactId>storm-core</artifactId>
     <version>0.9.3</version>
     <scope>provided</scope>
   </dependency>
"""

#JAVA Demo:创建一个Spout读取数据;创建bolt处理数据;创建一个Topology提交到集群；
$ git clone https://github.com/storm-book/examples-ch02-getting_started
"""
   #创建一个Spout作为数据源
   public class WordReader implements IRichSpout {
    	private static final long serialVersionUID = 1L;
    	private SpoutOutputCollector collector;
    	private FileReader fileReader;
    	private boolean completed = false;    

    	public boolean isDistributed() {
    		return false;
    	}
    	/**
    	 * 这是第一个方法，里面接收了三个参数，第一个是创建Topology时的配置，
    	 * 第二个是所有的Topology数据，第三个是用来把Spout的数据发射给bolt
    	 * **/
    	@Override
    	public void open(Map conf, TopologyContext context, SpoutOutputCollector collector) {
    		try {
    			//获取创建Topology时指定的要读取的文件路径
    			this.fileReader = new FileReader(conf.get("wordsFile").toString());
    		} catch (FileNotFoundException e) {
    			throw new RuntimeException("Error reading file
    					+ conf.get("wordFile"));
    		}
    		//初始化发射器
    		this.collector = collector;    

    	}
    	/**
    	 * 这是Spout最主要的方法，在这里我们读取文本文件，并把它的每一行发射出去（给bolt）
    	 * 这个方法会不断被调用.，为了降低它对CPU的消耗，当任务完成时让它sleep一下
    	 * **/
    	@Override
    	public void nextTuple() {
    		if (completed) {
    			try {
    				Thread.sleep(1000);
    			} catch (InterruptedException e) {
    				// Do nothing
    			}
    			return;
    		}
    		String str;
    		// Open the reader
    		BufferedReader reader = new BufferedReader(fileReader);
    		try {
    			// Read all lines
    			while ((str = reader.readLine()) != null) {
    				/**
    				 * 发射每一行，Values是一个ArrayList的实现
    				 */
    				this.collector.emit(new Values(str), str);
    			}
    		} catch (Exception e) {
    			throw new RuntimeException("Error reading tuple", e);
    		} finally {
    			completed = true;
    		}    

    	}
    	@Override
    	public void declareOutputFields(OutputFieldsDeclarer declarer) {
    		declarer.declare(new Fields("line"));    

    	}
    	@Override
    	public void close() {
    		// TODO Auto-generated method stub
    	}
    	
    	@Override
    	public void activate() {
    		// TODO Auto-generated method stub    

    	}
    	@Override
    	public void deactivate() {
    		// TODO Auto-generated method stub    

    	}
    	@Override
    	public void ack(Object msgId) {
    		System.out.println("OK:" + msgId);
    	}
    	@Override
    	public void fail(Object msgId) {
    		System.out.println("FAIL:" + msgId);    

    	}
    	@Override
    	public Map<String, Object> getComponentConfiguration() {
    		// TODO Auto-generated method stub
    		return null;
    	}
    }

"""

"""
   #创建两个bolt来处理Spout发射出的数据
   #第一个bolt：WordNormalizer(Bolt中最重要的是execute方法;每当一个tuple传过来时它便会被调用;)
   public class WordNormalizer implements IRichBolt {
    	private OutputCollector collector;
    	@Override
    	public void prepare(Map stormConf, TopologyContext context,
    			OutputCollector collector) {
    		this.collector = collector;
    	}
    	/**这是bolt中最重要的方法，每当接收到一个tuple时，此方法便被调用
    	 * 这个方法的作用就是把文本文件中的每一行切分成一个个单词，并把这些单词发射出去(给下一个bolt处理)
    	 * **/
    	@Override
    	public void execute(Tuple input) {
    		String sentence = input.getString(0);
    		String[] words = sentence.split(" ");
    		for (String word : words) {
    			word = word.trim();
    			if (!word.isEmpty()) {
    				word = word.toLowerCase();
    				// Emit the word
    				List a = new ArrayList();
    				a.add(input);
    				collector.emit(a, new Values(word));
    			}
    		}
    		//确认成功处理一个tuple
    		collector.ack(input);
    	}
    	@Override
    	public void declareOutputFields(OutputFieldsDeclarer declarer) {
    		declarer.declare(new Fields("word"));    

    	}
    	@Override
    	public void cleanup() {
    		// TODO Auto-generated method stub    

    	}
    	@Override
    	public Map<String, Object> getComponentConfiguration() {
    		// TODO Auto-generated method stub
    		return null;
    	}
    }
       
"""    

"""
   #创建两个bolt来处理Spout发射出的数据
   #第二个bolt:WordCounter
   public class WordCounter implements IRichBolt {
    	Integer id;
    	String name;
    	Map<String, Integer> counters;
    	private OutputCollector collector;    

    	@Override
    	public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
    		this.counters = new HashMap<String, Integer>();
    		this.collector = collector;
    		this.name = context.getThisComponentId();
    		this.id = context.getThisTaskId();    

    	}
    	@Override
    	public void execute(Tuple input) {
    		String str = input.getString(0);
    		if (!counters.containsKey(str)) {
    			counters.put(str, 1);
    		} else {
    			Integer c = counters.get(str) + 1;
    			counters.put(str, c);
    		}
    		// 确认成功处理一个tuple
    		collector.ack(input);
    	}
    	/**
    	 * Topology执行完毕的清理工作，比如关闭连接、释放资源等操作都会写在这里
    	 * 因为这只是个Demo，我们用它来打印我们的计数器
    	 * */
    	@Override
    	public void cleanup() {
    		System.out.println("-- Word Counter [" + name + "-" + id + "] --");
    		for (Map.Entry<String, Integer> entry : counters.entrySet()) {
    			System.out.println(entry.getKey() + ": " + entry.getValue());
    		}
    		counters.clear();
    	}
    	@Override
    	public void declareOutputFields(OutputFieldsDeclarer declarer) {
    		// TODO Auto-generated method stub    

    	}
    	@Override
    	public Map<String, Object> getComponentConfiguration() {
    		// TODO Auto-generated method stub
    		return null;
    	}
    }

"""
    

"""
    #在main函数中创建一个Topology
    public class WordCountTopologyMain {
     	public static void main(String[] args) throws InterruptedException {
     		//定义一个Topology
     		TopologyBuilder builder = new TopologyBuilder();
     		builder.setSpout("word-reader",new WordReader());
     		builder.setBolt("word-normalizer", new WordNormalizer())
     		       .shuffleGrouping("word-reader");
     		builder.setBolt("word-counter", new WordCounter(),2)
     		       .fieldsGrouping("word-normalizer", new Fields("word"));
     		//配置
     		Config conf = new Config();
     		conf.put("wordsFile", "d:/text.txt");
     		conf.setDebug(false);
     		//提交Topology
     		conf.put(Config.TOPOLOGY_MAX_SPOUT_PENDING, 1);
     		//创建一个本地模式cluster
     		LocalCluster cluster = new LocalCluster();
     		cluster.submitTopology("Getting-Started-Toplogie", conf,builder.createTopology());
     		Thread.sleep(1000);
     		cluster.shutdown();
     	}
    }
"""