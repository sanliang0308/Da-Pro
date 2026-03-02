CREATE OR REPLACE FUNCTION "imuser"."iot_dapro_save_mesinfo_v1"("i_data" json)
  RETURNS "pg_catalog"."json" AS $BODY$ 
const func_name = "iot_dapro_save_mesinfo_v1";
const results = { result: 0, message: '', data: {}, code: '' };

try {
    // 验证必要参数
    if (!i_data.vehicle_code || !i_data.mes_response) {
        results["result"] = 0;
        results["message"] = "缺少必要参数: vehicle_code 或 mes_response";
        results["code"] = "MISSING_PARAM";
        return results;
    }

    const vehicle_code = i_data.vehicle_code;
    const mes_response = i_data.mes_response;
    const device = i_data.device;
    const ts = i_data.ts;

    // 提取字段
    const substrate_id = mes_response.vehicleCode || vehicle_code;
    const lot_id = mes_response.drawingName;
    const order_no = mes_response.order;
    const item_list = mes_response.itemList;
    const pass_count = parseInt(mes_response.passCount) || 0;
    const fail_count = parseInt(mes_response.failCount) || 0;
    const total_count = parseInt(mes_response.colCount) || 0;

    if (!item_list || !Array.isArray(item_list)) {
        results["result"] = 0;
        results["message"] = "itemList为空或不是数组";
        results["code"] = "INVALID_DATA";
        return results;
    }

    let inserted_count = 0;
    let updated_count = 0;
    const processed_sns = [];

    // 处理每个item
    for (let i = 0; i < item_list.length; i++) {
        const item = item_list[i];
        const mes_sn = item.sn;
        
        if (!mes_sn) {
            continue;
        }

        processed_sns.push(mes_sn);
        
        const tx = parseInt(item.colNum) || 0;
        const ty = parseInt(item.rowNum) || 0;
        const bin_code = parseInt(item.binCode) || 0;

        // 使用UPSERT (INSERT ... ON CONFLICT) 语句
        const upsert_sql = `
            INSERT INTO imuser.e142_strip_transfer (
                created_at,
                updated_at,
                source_ts,
                substrate_id,
                lot_id,
                tx,
                ty,
                mes_sn,
                substrate_type,
                status,
                supplier_name,
                good_devices,
                device_name,
                order_no
            ) VALUES (
                NOW(),
                NOW(),
                to_timestamp($1 / 1000.0),
                $2,
                $3,
                $4,
                $5,
                $6,
                'Strip',
                'SLM',
                'MES_SUPPLIER',
                $7,
                $8,
                $9
            )
            ON CONFLICT (mes_sn) 
            DO UPDATE SET
                updated_at = NOW(),
                substrate_id = EXCLUDED.substrate_id,
                lot_id = EXCLUDED.lot_id,
                tx = EXCLUDED.tx,
                ty = EXCLUDED.ty,
                source_ts = EXCLUDED.source_ts,
                good_devices = EXCLUDED.good_devices,
                device_name = EXCLUDED.device_name,
                order_no = EXCLUDED.order_no
            RETURNING id
        `;

        const result = plv8.execute(upsert_sql, [
            mes_response.timestamp,
            substrate_id,
            lot_id,
            tx,
            ty,
            mes_sn,
            pass_count,
            device,
            order_no
        ]);

        if (result.length > 0) {
            if (result[0].id) {
                // 如果是新插入的记录，id会被返回
                inserted_count++;
            } else {
                updated_count++;
            }
        }
    }

    results["result"] = 1;
    results["message"] = "success";
    results.data = {
        inserted_count: inserted_count,
        updated_count: updated_count,
        total_processed: inserted_count + updated_count,
        processed_sns: processed_sns
    };

    return results;

} catch (e) {
    plv8.elog(NOTICE, '错误信息:', e.message);
    results["result"] = 0;
    results["message"] = func_name + ',' + e.message;
    results["code"] = "SYSTEM_ERROR";
    return results;
}
$BODY$
  LANGUAGE plv8 IMMUTABLE STRICT
  COST 100