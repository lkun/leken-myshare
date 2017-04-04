package com.lion.leken.myshare.mybatis.impl;

import com.lion.leken.myshare.core.BaseShare;
import org.apache.ibatis.mapping.ParameterMapping;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

/**
 *
 */
public class TableShareByDateStrategy implements BaseShare<ParameterMapping,Object> {
    @Override
    public String getTableName(List<ParameterMapping> paramsMapping, Object param , String tableName) {
        SimpleDateFormat sdf = new SimpleDateFormat("YYYY");
        StringBuilder sb = new StringBuilder(tableName);
        sb.append("_");
        sb.append(sdf.format(new Date()));
        return sb.toString();
    }
}
