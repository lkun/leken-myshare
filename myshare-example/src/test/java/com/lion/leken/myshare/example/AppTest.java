package com.lion.leken.myshare.example;

import com.lion.leken.myshare.example.entity.Orders;
import com.lion.leken.myshare.example.mapper.OrdersMapper;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest
public class AppTest {
    @Autowired
    private OrdersMapper ordersMapper;

    @Test
    public void test() {
        Orders orders = new Orders();
        orders.setId(2);
        orders.setInfo("info");
        //SharingUtils.setSuffix("01");
        ordersMapper.insert(orders);

        //SharingUtils.setSuffix("02");
        //ordersMapper.deleteByPrimaryKey(1);

        //orders.setInfo("info2");
        //ordersMapper.updateByPrimaryKey(orders);

        //SharingUtils.setSuffix("01"); //设置表后缀
        //ordersMapper.selectByPrimaryKey(1);
    }
}
