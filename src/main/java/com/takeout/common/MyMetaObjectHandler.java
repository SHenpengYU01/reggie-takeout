package com.takeout.common;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.takeout.utils.BaseContext;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 自定义元数据处理器
 * MP提供的自动填充功能，通过实现MetaObjectHandler(元数据处理器)，来实现服务
 * 为加入@TableField的注解提供自动填充的功能
 */
@Component
public class MyMetaObjectHandler implements MetaObjectHandler {

    /**
     * @param metaObject 插入时自动填充
     */
    @Override
    public void insertFill(MetaObject metaObject) {

        //填充创建时间
        metaObject.setValue("createTime", LocalDateTime.now());
        //填充 更新的时间
        metaObject.setValue("updateTime", LocalDateTime.now());
        //BaseContext工具类获取当前登陆人员信息
        //填充创建人信息
        Long currentId = BaseContext.getCurrentId();
        if (currentId != null) {
            metaObject.setValue("createUser", currentId);
            //填充更新人信息
            metaObject.setValue("updateUser", currentId);
        } else {
            // 如果无法获取当前用户ID，使用默认值避免数据库错误
            metaObject.setValue("createUser", 0L);
            metaObject.setValue("updateUser", 0L);
        }
    }

    /**
     * @param metaObject 更新时自动填充
     */
    @Override
    public void updateFill(MetaObject metaObject) {
        //因为是更新，所以不用操作创建时间
        //更新 更新的时间
        metaObject.setValue("updateTime", LocalDateTime.now());
        //更新更新人员
        Long currentId = BaseContext.getCurrentId();
        if (currentId != null) {
            metaObject.setValue("updateUser", currentId);
        } else {
            metaObject.setValue("updateUser", 0L);
        }
    }
}
