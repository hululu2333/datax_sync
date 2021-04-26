#!/bin/bash

a=$(cat ./ziyun-andon.increment | grep tableName= | sed 's/tableName=//g' | sed 's/ incrementField=//g' | grep a)

# 如果a为空，则该表必不在增量配置里。如果a不为空，还需要判断
if [ -n "${a}" ]; then
    array=(${a})
    for each in ${array[@]}
    do
        echo ${each}
        
        array1=(${each/,/ })

        increment_table_name=${array1[0]}
        increment_field_name=${array1[1]}


        echo "表名："${array1[0]}
        echo "字段名："${array1[1]}

        if [ andon_fault_tag_statistics_copy1 = ${increment_table_name} ]; then
            mode=increment
            echo "break"
            break
        fi
    done
fi

