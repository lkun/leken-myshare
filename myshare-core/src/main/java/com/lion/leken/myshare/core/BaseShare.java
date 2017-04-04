package com.lion.leken.myshare.core;

import java.util.List;

/**
 *
 */
public interface BaseShare<T,V> {
    /**
     * 根据参数获取分表后的表名
     */
    public String getTableName(List<T> tList, V v, String tableName);
}
