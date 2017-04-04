package com.lion.leken.myshare.core;

/**
 *
 */
public enum ShareTableEnum {
    TableShareByDateStrategy("TableShareByDateStrategy", "TableShareByDateStrategy"),
    TableTypeShareStrategy("TableTypeShareStrategy", "TableTypeShareStrategy");

    private String tableName;
    private String share;


    ShareTableEnum(String tableName, String share) {
        this.tableName = tableName;
        this.share = share;
    }

    public String getTableName() {
        return tableName;
    }

    public String getShare() {
        return share;
    }
}
