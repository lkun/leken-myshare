package com.lion.leken.myshare.mybatis.factory;

import com.lion.leken.myshare.core.BaseShare;
import com.lion.leken.myshare.core.ShareTableEnum;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 *
 */
public class ShareFactory {
    private static Logger logger = LoggerFactory.getLogger(ShareFactory.class);

    private static Map<String, BaseShare> shareMap;

    static {
        // 初始化工厂map，构造单例的路由集合
        shareMap = new HashMap<>();
        for (ShareTableEnum shareTableEnum : ShareTableEnum.values()){
            try {
                Class shardClass = Class.forName("com.lion.leken.myshare.mybatis.impl." + shareTableEnum.getShare());
                shareMap.put(shareTableEnum.getTableName(), (BaseShare)shardClass.newInstance());
            }catch (Exception e){
                logger.error("初始化share异常,tableName={}, class={}",
                        shareTableEnum.getTableName(), shareTableEnum.getShare());
            }
        }
    }

    public static BaseShare getShare(String tableName){
        return shareMap.get(tableName);
    }

    public static void main(String[] args) {
        getShare("TableShareByDateStrategy");
    }
}
