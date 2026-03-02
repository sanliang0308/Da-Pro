# Da-Pro 设备数据处理项目

这是一个设备数据处理项目，主要包含以下几个部分：

## 目录结构

- `database/schema`: 存放数据库表结构定义文件 (SQL)。
- `database/plv8`: 存放 PLV8 存储过程逻辑。
- `node-red`: 存放 Node-RED 处理逻辑和流文件。

## 项目说明

本项目用于处理设备数据，通过 Node-RED 进行数据采集和预处理，并使用 PLV8 在数据库层面进行复杂逻辑处理。


1、先接收请求MES的数据，EMap/DaPro1/mes_response
调用存储过程：

msg.query = "SELECT imuser.iot_dapro_save_mesinfo_v1($1::json)";
msg.params = [msg.payload];

return msg;
把数据存到e142_strip_transfer 表中

2、产品打印完成以后，上传数据含有打印晶圆坐标的信息，xml,转为json,调用存储过程：
iot_dapro_save_dapro_info_v1
把打印的坐标更新到e142_strip_transfer 表中