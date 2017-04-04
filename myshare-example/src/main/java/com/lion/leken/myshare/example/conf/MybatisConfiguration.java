package com.lion.leken.myshare.example.conf;

import com.alibaba.druid.pool.DruidDataSource;
import com.alibaba.druid.util.JdbcConstants;
import com.lion.leken.myshare.mybatis.ShareInterceptor;
import org.apache.ibatis.jdbc.RuntimeSqlException;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.annotation.MapperScan;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;

import javax.sql.DataSource;
import java.util.Properties;

@Configuration
@MapperScan(basePackages = {"com.lion.leken.myshare.example.mapper"})
public class MybatisConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(MybatisConfiguration.class);
    @Autowired
    private Environment env;

    @Bean
    public DataSource dataSource() {
        DruidDataSource druidDataSource = new DruidDataSource();
        druidDataSource.setPassword(env.getProperty("jdbc.password"));
        druidDataSource.setUsername(env.getProperty("jdbc.username"));
        //初始化连接数量
        druidDataSource.setInitialSize(Integer.parseInt(env.getProperty("jdbc.InitialSize")));
        //最大并发连接数
        druidDataSource.setMaxActive(Integer.parseInt(env.getProperty("jdbc.MaxActive")));
        //最小空闲连接数
        druidDataSource.setMinIdle(Integer.parseInt(env.getProperty("jdbc.MinIdle")));
        //配置获取连接等待超时的时间
        druidDataSource.setMaxWait(Integer.parseInt(env.getProperty("jdbc.MaxWait")));
        //超过时间限制是否回收
        druidDataSource.setRemoveAbandoned(Boolean.getBoolean(env.getProperty("jdbc.RemoveAbandoned")));
        //配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒
        druidDataSource.setTimeBetweenEvictionRunsMillis(Integer.parseInt(env.getProperty("jdbc.TimeBetweenEvictionRunsMillis")));
        //配置一个连接在池中最小生存的时间，单位是毫秒
        druidDataSource.setMinEvictableIdleTimeMillis(Integer.parseInt(env.getProperty("jdbc.MinEvictableIdleTimeMillis")));
        druidDataSource.setUrl(env.getProperty("jdbc.url"));
        druidDataSource.setDriverClassName(env.getProperty("jdbc.driver"));
        druidDataSource.setMaxActive(Integer.parseInt(env.getProperty("jdbc.poolMaximumActiveConnections")));
        return druidDataSource;
    }


    @Bean
    public SqlSessionFactory sqlSessionFactory() {
        try {
            SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
            sessionFactory.setDataSource(dataSource());
            sessionFactory.setMapperLocations(new PathMatchingResourcePatternResolver()
                    .getResources("classpath:mapping/*.xml"));
            ShareInterceptor shareInterceptor = new ShareInterceptor();
            Properties properties = new Properties();
            properties.setProperty("segmentation", "orders:1,users:1");
            properties.setProperty("ignoreTable", "");
            shareInterceptor.setProperties(properties);
            sessionFactory.setPlugins(new Interceptor[]{shareInterceptor});
            return sessionFactory.getObject();
        } catch (Exception e) {
            logger.error("not install sessionFactory", e);
            throw new RuntimeSqlException("not install sessionFactory");
        }
    }

    @Bean
    public DataSourceTransactionManager transaction() {
        return new DataSourceTransactionManager(dataSource());
    }
}
