#!/bin/bash

# 先定义好各个可能需要的路径
BASE_PATH=$(cd `dirname $0`;pwd)
CONF_DIR=${BASE_PATH}/../conf
JOB_DIR=${BASE_PATH}/../job
JAR_DIR=${BASE_PATH}/../jar

echo "脚本所在路径："${BASE_PATH}
echo "表配置所在路径："${CONF_DIR}
echo "json文件所在路径："${JOB_DIR}
echo "jar包所在路径："${JAR_DIR}
echo ""


# 各个数据源的配置 jdbc:mysql://192.168.0.124:3306/test
mysql_url=$(cat ${CONF_DIR}/databases.properties | grep mysql_url | sed 's/mysql_url=//g')
mysql_username=$(cat ${CONF_DIR}/databases.properties | grep mysql_username | sed 's/mysql_username=//g')
mysql_password=$(cat ${CONF_DIR}/databases.properties | grep mysql_password | sed 's/mysql_password=//g')

hive_path=$(cat ${CONF_DIR}/databases.properties | grep hive_path | sed 's/hive_path=//g')

oracle_url=$(cat ${CONF_DIR}/databases.properties | grep oracle_url | sed 's/oracle_url=//g')
oracle_username=$(cat ${CONF_DIR}/databases.properties | grep oracle_username | sed 's/oracle_username=//g')
oracle_password=$(cat ${CONF_DIR}/databases.properties | grep oracle_password | sed 's/oracle_password=//g')

function check_main_args()
{
  if [ $# -lt 3 ]; then
    echo "Usage: datax_sync <source_database_type> <source_database_name> <target_database_type>"
	echo "such as: mysql ziyun-iot hive"
    exit 1
  fi
}
check_main_args $@


# 判断数据源类型，url是jdbc连接数据库所需的url，path是储存表配置文件的路径
if [ $1 = mysql ]; then
    url=${mysql_url}${2}
    path=${CONF_DIR}/${mysql_url//\//}
    echo "数据源表配置文件的储存路径："${path}
    echo ""

    java -classpath ${JAR_DIR}/get_structure_from_databases-1.0-SNAPSHOT-jar-with-dependencies.jar com.hu.GenerateStructureFromMysql ${url} ${path} ${mysql_username} ${mysql_password}
    echo "数据源表配置生成成功"

elif [ $1 = oracle ]; then
    path=${CONF_DIR}/${oracle_url}
    echo "数据源表配置文件的储存路径："${path}
    echo ""

    java -classpath ${JAR_DIR}/get_structure_from_databases-1.0-SNAPSHOT-jar-with-dependencies.jar com.hu.GenerateStructureFromOracle ${oracle_url} ${path} ${oracle_username} ${oracle_password}

else
    echo "输入的数据源类型错误，或暂时还不支持"
    echo "程序退出"
    exit 1
fi


# 判断目标数据库类型，hive_database_path是被同步的库在hdfs上的储存路径
if [ $3 = hive ]; then
    hive_database_name=$1_${2//-/_}
    hive_database_name=${hive_database_name//#/}
    hive_database_path=${hive_path}${hive_database_name}

    echo "开始执行hive的建库建表语句"
    ${BASE_PATH}/create_hive_table ${hive_database_name} ${path}/$2

    echo "将数据源数据以append模式加载到hdfs" #四个参数分别为源数据库类型，源数据库名，源数据库配置文件所在路径，hive数据库在hdfs的储存路径
    ${BASE_PATH}/load_to_hive $1 $2 ${path}/$2 $hive_database_path

    #echo "判断数据是否成功加载，如果加载成功，则将之前导入的旧数据删除。如果失败，做出一些提示"
    #${BASE_PATH}/verify_load_result
else
    echo "输入的数据源类型错误，或暂时还不支持"
    echo "程序退出"
    exit 1
fi
