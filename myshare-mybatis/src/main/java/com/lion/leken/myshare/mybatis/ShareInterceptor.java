package com.lion.leken.myshare.mybatis;

import com.lion.leken.myshare.core.BaseShare;
import com.lion.leken.myshare.mybatis.factory.ShareFactory;
import org.apache.ibatis.executor.statement.StatementHandler;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.ParameterMapping;
import org.apache.ibatis.plugin.*;
import org.apache.ibatis.reflection.DefaultReflectorFactory;
import org.apache.ibatis.reflection.MetaObject;
import org.apache.ibatis.reflection.ReflectorFactory;
import org.apache.ibatis.reflection.factory.DefaultObjectFactory;
import org.apache.ibatis.reflection.factory.ObjectFactory;
import org.apache.ibatis.reflection.wrapper.DefaultObjectWrapperFactory;
import org.apache.ibatis.reflection.wrapper.ObjectWrapperFactory;

import java.sql.Connection;
import java.util.*;

/**
 *
 */
@Intercepts({@Signature(type = StatementHandler.class, method = "prepare", args = {Connection.class, Integer.class})})
public class ShareInterceptor implements Interceptor {
    private static final ObjectFactory DEFAULT_OBJECT_FACTORY = new DefaultObjectFactory();
    private static final ObjectWrapperFactory DEFAULT_OBJECT_WRAPPER_FACTORY = new DefaultObjectWrapperFactory();
    private static final ReflectorFactory DEFAULT_REFLECTOR_FACTORY = new DefaultReflectorFactory();
    public Set<String> ignoreTable = new HashSet<>();
    private static Map<String, String> tableStrategyMap = new HashMap<>();

    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        StatementHandler statementHandler = (StatementHandler) invocation.getTarget();
        // 保存会话信息
        MetaObject metaStatementHandler = MetaObject.forObject(statementHandler,
                DEFAULT_OBJECT_FACTORY, DEFAULT_OBJECT_WRAPPER_FACTORY, DEFAULT_REFLECTOR_FACTORY);

        // 获取原sql
        BoundSql boundSql = (BoundSql) metaStatementHandler.getValue("delegate.boundSql");
        // 重写sql
        String newSql = getSql(boundSql);
        metaStatementHandler.setValue("delegate.boundSql.sql", newSql);
        // 将执行权交给下一个拦截器
        return invocation.proceed();
    }

    // 获取分表后的sql
    private String getSql(BoundSql boundSql) {
        // 0、获取sql
        String sql = boundSql.getSql().trim().toLowerCase();
        // 1、获取表名
        String tableName = getTableName(sql);
        // 2、获取新sql
        return getShardSql(sql, tableName, boundSql.getParameterMappings(), boundSql.getParameterObject());
    }

    // 根据sql获取表名
    private String getTableName(String sql) {
        String[] sqls = sql.split("\\s+");
        switch (sqls[0]) {
            case "select": {
                // select aa,bb,cc from tableName
                for (int i = 0; i < sqls.length; i++) {
                    if (sqls[i].equals("from")) {
                        return sqls[i + 1];
                    }
                }
                break;
            }
            case "update": {
                // update tableName
                return sqls[1];
            }
            case "insert": {
                // insert into tableName
                return sqls[2];
            }
            case "delete": {
                // delete tableName
                return sqls[1];
            }
        }
        return null;
    }

    // 构造新sql
    private String getShardSql(String sql, String tableName, List<ParameterMapping> paramsMapping, Object params) {
        // 判断是否需要路由策略
        BaseShare baseShare = ShareFactory.getShare(tableStrategyMap.get(tableName));
        if (baseShare == null) {
            return sql;
        }
        String shardTableName = baseShare.getTableName(paramsMapping, params, tableName);
        return sql.replaceFirst(tableName, shardTableName);
    }

    @Override
    public Object plugin(Object target) {
        if (target instanceof StatementHandler) {
            return Plugin.wrap(target, this);
        } else {
            return target;
        }
    }

    @Override
    public void setProperties(Properties properties) {
        String segmentation = properties.getProperty("segmentation");
        if (segmentation.isEmpty()) {
            return;
        }
        if (!segmentation.endsWith(",")) {
            String[] tablesProperties = segmentation.split(",");
            for (String tablesProperty : tablesProperties) {
                if (!tablesProperty.endsWith(":")) {
                    String[] tableProperty = tablesProperty.split(":");
                    if (tableProperty[1].equals("0")) {
                        tableStrategyMap.put(tableProperty[0], "TableShareByDateStrategy");
                    } else {
                        tableStrategyMap.put(tableProperty[0], "TableTypeShareStrategy");
                    }
                }
            }
        }
        String ignoreTable = properties.getProperty("ignoreTable");
        if (ignoreTable != null) {
            String[] ignoreTables = ignoreTable.split(",");
            for (String table : ignoreTables) {
                this.ignoreTable.add(table);
            }
        }
    }
}
