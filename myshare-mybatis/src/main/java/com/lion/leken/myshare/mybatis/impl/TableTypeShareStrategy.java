package com.lion.leken.myshare.mybatis.impl;

import com.lion.leken.myshare.core.BaseShare;
import org.apache.ibatis.mapping.ParameterMapping;

import java.util.List;

/**
 *
 */
public class TableTypeShareStrategy implements BaseShare<ParameterMapping,Object> {
    @Override
    public String getTableName(List<ParameterMapping> paramsMapping, Object param, String tableName) {
        for (ParameterMapping para : paramsMapping) {
            if (para.getProperty().equals("info")) {
                int index = ((Integer) param) % 2 + 1;
                return tableName + "_" + index;
            }
        }
        return tableName;
    }
}
