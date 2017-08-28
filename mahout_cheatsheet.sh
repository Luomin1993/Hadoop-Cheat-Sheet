========================Install=========================
$ wget http://archive.apache.org/dist/mahout/0.9/mahout-distribution-0.9.tar.gz -P /download;cd /download;tar -zxvf mahout-distribution-0.9.tar.gz -C /usr/lib;mv /usr/lib/mahout-distribution-0.9 /usr/lib/mahout;
$ echo "export MAHOUT_HOME=/usr/lib/mahout" >> /etc/profile;echo "export PATH=$PATH:$MAHOUT_HOME/conf:$MAHOUT_HOME/bin" >> /etc/profile;source /etc/profile;
$ $MAHOUT_HOME/bin/mahout

#运行mahout的算法
$ hadoop fs -mkdir testdata 
$ wget http://archive.ics.uci.edu/ml/databases/synthetic_control/synthetic_control.data -P /download #下载测试数据
$ hadoop fs -put /download/synthetic_control.data testdata/     #必须放在这个目录中,因为我经过测试知道官方给出的测试jar中的输入路径就是/user/root/testdata;
$ hadoop jar /usr/lib/mahout/mahout-examples-0.9.jar  org.apache.mahout.clustering.syntheticcontrol.kmeans.Job #如果出现错误,名称是缺少 AbstractJob类,这时候我们需要将mahout安装目录不是(mahout lib目录)下的除了example.jar,所有jar包复制到hadoop的lib目录下;重新启动hadoop;然后运行上面的命令;
$ hadoop fs -ls /user/root/output #查看聚类结果

---------------------------新闻分类示例-------------------------------
#生成input的数据 
$ $MAHOUT_HOME/bin/mahout org.apache.mahout.classifier.bayes.PrepareTwentyNewsgroups 
                          -p examples/bin/work/20news-bydate/20news-bydate-train       #输入数据路径:来自20news-bydate.tar.gz数据
                          -o examples/bin/work/20news-bydate/bayes-train-input         #输出
                          -a org.apache.mahout.vectorizer.DefaultAnalyzer              #调包
                          -c UTF-8

#生成test的数据 
$ $MAHOUT_HOME/bin/mahout org.apache.mahout.classifier.bayes.PrepareTwentyNewsgroups       
                          -p examples/bin/work/20news-bydate/20news-bydate-test           #输入数据路径:来自20news-bydate.tar.gz数据
                          -o examples/bin/work/20news-bydate/bayes-test-input             #输出
                          -a org.apache.mahout.vectorizer.DefaultAnalyzer                 #调包
                          -c UTF-8  
$ start-all.sh
$ hadoop dfs -put $MAHOUT_HOME/examples/bin/work/20news-bydate/bayes-train-input 20news-input  
#基于Tri-grams训练贝叶斯分类器 
$ $MAHOUT_HOME/bin/mahout trainclassifier  
                          -i 20news-input/bayes-train-input  
                          -o newsmodel  
                          -type bayes  
                          -ng 3  
                          -source hdfs                            
#在input目录运行Test
$ $MAHOUT_HOME/bin/mahout testclassifier  
                          -m newsmodel  
                          -d 20news-input  
                          -type bayes  
                          -ng 3  
                          -source hdfs  
                          -method mapreduce



=======================Cheat Cheat========================

#简单推荐系统demo;
"""
    //HelloMahout.java
    import org.apache.mahout.cf.taste.model.DataModel;
    import org.apache.mahout.cf.taste.recommender.Recommender;
    import org.apache.mahout.cf.taste.similarity.UserSimilarity;
    //并未展示所有导入

    public class HelloMahout {
     
         public static void main(String[] args) {
             
             Logger logger=Logger.getLogger(HelloMahout.class);
             try {
                 //读取用户评分数据,封装成一个DataModel
                 DataModel model = new FileDataModel(new File("F:\\360Downloads\\info.csv"));
                 // 根据相似度找出对应的好朋友的标准
                 UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(model);
                 // 邻域:选择两个好朋友帮我推荐
                 UserNeighborhood userNeighborhood = new NearestNUserNeighborhood(2,userSimilarity, model);
                 // 构建推荐引擎
                 Recommender recommender = new GenericUserBasedRecommender(model,userNeighborhood, userSimilarity);
                 // 进行推荐
                 List<RecommendedItem> recommend = recommender.recommend(1, 5);
                 // 打印结果
                 for (RecommendedItem item : recommend) {
                     logger.info(item);
                 }
             } catch (Exception e) {
                 logger.error(e.getMessage());
             }
         }
     }
"""

#查看文件
$ bin/mahout cat donut.csv

#根据数据训练生成logistic model
$ $MAHOUT_HOME/bin/mahout trainlogistic --input donut.csv                        #使用指定的文件和资源输入
                                        --output ./model                         #将训练的模型导入指定的文件      
                                        --target color                           #使用指定的变量为目标
                                        --categories 2                           #有多少类的目标变量         
                                        --predictors x y                         #列表中的预测变量的名称              
                                        --types numeric                          #预测变量的类型:numeric/word/text          
                                        --features 20 --passes 100 --rate 50     #内部特征向量的大小;对新输入数据应重训练次数;初始学习率;

#运行logistic model
$ $MAHOUT_HOME/bin/mahout runlogistic --input donut.csv                          #从指定的文件或资源读取数据记录
                                      --model ./model                            #使用的模型
                                      --auc                                      #打印准确率 
                                      --confusion                                #打印混淆矩阵  


#KMeans聚类demo;
"""
    //SimpleKMeansClustering.java
    import org.apache.hadoop.fs.FileSystem;
    import org.apache.mahout.clustering.kmeans.Cluster;
    import org.apache.mahout.math.VectorWritable;
    //并未展示所有导入
    
    public class SimpleKMeansClustering {
      public static final double[][] points = { {1, 1}, {2, 1}, {1, 2},{2, 2}, {3, 3}, {8, 8},{9, 8}, {8, 9}, {9, 9}};

      //写入文件;依赖SequenceFile.Writer;
      public static void writePointsToFile(List<Vector> points,
                                           String fileName,
                                           FileSystem fs,
                                           Configuration conf) throws IOException {
        Path path = new Path(fileName);
        SequenceFile.Writer writer = new SequenceFile.Writer(fs, conf,
            path, LongWritable.class, VectorWritable.class);
        long recNum = 0;
        VectorWritable vec = new VectorWritable();
        for (Vector point : points) {
          vec.set(point);
          writer.append(new LongWritable(recNum++), vec);
        }
        writer.close();
      }
      
      //二维数组转换为List<Vector>;
      public static List<Vector> getPoints(double[][] raw) {
        List<Vector> points = new ArrayList<Vector>();
        for (int i = 0; i < raw.length; i++) {
          //每次读入raw的一行;
          double[] fr = raw[i];
          Vector vec = new RandomAccessSparseVector(fr.length);
          vec.assign(fr);
          points.add(vec);
        }
        return points;
      }
      
      public static void main(String args[]) throws Exception {
        
        int k = 2; //指定簇的个数
        
        List<Vector> vectors = getPoints(points); 
        
        //创建数据目录
        File testData = new File("testdata");
        if (!testData.exists()) {
          testData.mkdir();
        }
        testData = new File("testdata/points");
        if (!testData.exists()) {
          testData.mkdir();
        }
        
        Configuration conf = new Configuration();
        FileSystem fs = FileSystem.get(conf);
        writePointsToFile(vectors, "testdata/points/file1", fs, conf);
        
        Path path = new Path("testdata/clusters/part-00000");
        SequenceFile.Writer writer = new SequenceFile.Writer(fs, conf,
            path, Text.class, Cluster.class);
        
        for (int i = 0; i < k; i++) {
          Vector vec = vectors.get(i);
          Cluster cluster = new Cluster(vec, i, new EuclideanDistanceMeasure());
          writer.append(new Text(cluster.getIdentifier()), cluster);
        }
        writer.close();
        
        //运行K-Means算法
        KMeansDriver.run(conf, new Path("testdata/points"), new Path("testdata/clusters"),
          new Path("output"), new EuclideanDistanceMeasure(), 0.001, 10,
          true, false);
        
        //读取输出,打印向量和簇ID;
        SequenceFile.Reader reader = new SequenceFile.Reader(fs,
            new Path("output/" + Cluster.CLUSTERED_POINTS_DIR
                     + "/part-m-00000"), conf);
        
        IntWritable key = new IntWritable();
        WeightedVectorWritable value = new WeightedVectorWritable();
        while (reader.next(key, value)) {
          System.out.println(value.toString() + " belongs to cluster "
                             + key.toString());
        }
        reader.close();
      }
      
    }
"""

#特征编码:文本的词条化和向量化;
"""
    //TokenizingAndVectorizingText.java
    import org.apache.lucene.analysis.TokenStream;
    import org.apache.mahout.math.SequentialAccessSparseVector;
    import org.apache.mahout.vectorizer.encoders.FeatureVectorEncoder;
    //并未展示所有导入    

    public class TokenizingAndVectorizingText {    

      public static void main(String[] args) throws IOException {
        //将文本分割为单词
        FeatureVectorEncoder encoder = new StaticWordValueEncoder("text");
        Analyzer analyzer = new StandardAnalyzer(Version.LUCENE_31);         

        StringReader in = new StringReader("text to magically vectorize");
        TokenStream ts = analyzer.tokenStream("body", in);
        TermAttribute termAtt = ts.addAttribute(TermAttribute.class);    

        //编码为维度大小为100的向量(100个特征?)
        Vector v1 = new RandomAccessSparseVector(100);                   
        while (ts.incrementToken()) {
          char[] termBuffer = termAtt.termBuffer();
          int termLen = termAtt.termLength();
          String w = new String(termBuffer, 0, termLen);    
          //单词w添加到v1;             
          encoder.addToVector(w, 1, v1);                                 
        }
        System.out.printf("%s\n", new SequentialAccessSparseVector(v1));
      }    

    }
    //在mahout中,向量被实现为三个不同的类,每个类都是针对不同场景优化的：DenseVector、RandomAccessSparseVector和SequentialAccessSparseVector；
"""