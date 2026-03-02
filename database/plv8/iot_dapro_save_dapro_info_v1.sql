CREATE OR REPLACE FUNCTION "imuser"."iot_dapro_save_dapro_info_v1"("i_data" json)
  RETURNS "pg_catalog"."json" AS $BODY$ 
/*
  * Description：更新贴片机传输数据
  * Auth:zhangyanrong
  * Date: 2025-01-15
  * version: 1.0
  * 调用示例
    select iot_dapro_save_dapro_info_v1($1::json)
  * 返回示例
    {
    "code": "",
    "data": {
        "updated_count": 2
    },
    "message": "success",
    "result": 1
    }
*/
const func_name = "iot_dapro_save_dapro_info_v1";
const results = { result: 0, message: '', data: {}, code: '' };

try {
    // 验证必要参数
    if (!i_data.excResult) {
        results["result"] = 0;
        results["message"] = "缺少必要参数: excResult";
        results["code"] = "MISSING_PARAM";
        return results;
    }

    const excResult = i_data.excResult;
    
    if (!Array.isArray(excResult) || excResult.length === 0) {
        results["result"] = 0;
        results["message"] = "excResult为空或不是数组";
        results["code"] = "INVALID_DATA";
        return results;
    }

    plv8.elog(NOTICE, '开始处理数据, 记录数:', excResult.length);

    let updated_count = 0;
    const errors = [];

    // 处理每条记录
    for (let i = 0; i < excResult.length; i++) {
        const record = excResult[i];
        
        // 提取必要字段
        const substrate_id = record.SubstrateId;
        const from_substrate_id = record.FromSubstrateId;
        const tx = parseInt(record.TX) || 0;
        const ty = parseInt(record.TY) || 0;
        
        const fx = parseInt(record.FX) || 0;
        const fy = parseInt(record.FY) || 0;
        
        const dimension_x = parseInt(record.DimensionX) || 0;
        const dimension_y = parseInt(record.DimensionY) || 0;
        const ts = record.ts;
        
        if (!substrate_id || !from_substrate_id) {
            plv8.elog(NOTICE, '跳过缺少必要字段的记录');
            continue;
        }

        try {
            // 计算匹配条件,dimension_y - (ty);
            
            const ty_condition = dimension_y - (ty) ;
            
            const tx_condition = tx + 1 ;
            
            plv8.elog(NOTICE, `更新条件: substrate_id=${substrate_id}, tx=${tx_condition}, ty=${ty_condition}`);
            
            // 更新记录
            const update_sql = `
                UPDATE imuser.e142_strip_transfer 
                SET 
                    updated_at = NOW(),
                    fx = $1,
                    fy = $2,
                    source_ts = $3,
                    substrate_type = $4,
                    lot_id = $5,
                    good_devices = $6,
                    supplier_name = $7,
                    status = $8,
                    from_substrate_id = $9,
                    dapro_tx = $10,
                    dapro_ty = $11
                WHERE tx = $12
                  AND ty = $13
                  AND substrate_id = $14
            `;
            
            const update_result = plv8.execute(update_sql, [
                fx,
                fy,
                ts,
                record.SubstrateType || 'Strip',
                record.LotId,
                parseInt(record.GoodDevices) || 0,
                record.SupplierName || 'MES_SUPPLIER',
                record.Status || 'SLM',
                from_substrate_id,
                tx,
                ty,
                tx_condition,
                ty_condition,
                substrate_id
            ]);
            
            // 检查是否更新了记录
            if (update_result && update_result.rowCount > 0) {
                updated_count += update_result.rowCount;
                plv8.elog(NOTICE, `成功更新记录: ${update_result.rowCount} 条`);
            } else {
                plv8.elog(NOTICE, `未找到匹配的记录: substrate_id=${substrate_id}, tx=${tx_condition}, ty=${ty_condition}`);
            }
            
        } catch (e) {
            plv8.elog(NOTICE, `处理记录时出错: ${e.message}`);
            errors.push(`记录 ${i}: ${e.message}`);
        }
    }

    results["result"] = 1;
    results["message"] = "success";
    results.data = {
        updated_count: updated_count
    };

    if (errors.length > 0) {
        results.data.errors = errors;
        results.message = `处理完成，但有 ${errors.length} 个错误`;
    }

    plv8.elog(NOTICE, `处理完成: 更新 ${updated_count} 条记录`);

    return results;

} catch (e) {
    plv8.elog(NOTICE, '函数执行错误:', e.message);
    results["result"] = 0;
    results["message"] = func_name + ',' + e.message;
    results["code"] = "SYSTEM_ERROR";
    return results;
}
$BODY$
  LANGUAGE plv8 IMMUTABLE STRICT
  COST 100