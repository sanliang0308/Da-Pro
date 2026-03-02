 CREATE TABLE e142_strip_transfer (
    id                  bigserial PRIMARY KEY,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),

    -- 源数据时间（这里用 Node-RED 解析时间，也可以以后改成设备上报时间）
    source_ts           timestamptz,

    substrate_type      text,
    substrate_id        text,
    lot_id              text,
    good_devices        integer,
    supplier_name       text,
    status              text,
    from_substrate_id   text,

    fx                  integer,
    fy                  integer,
    tx                  integer,
    ty                  integer,
    tz                  integer,
    dapro_tx            integer,
    dapro_ty            integer,
    "mes_sn" varchar(255) COLLATE "pg_catalog"."default",
    "device_name" varchar(255) COLLATE "pg_catalog"."default",
    "order_no" varchar(255) COLLATE "pg_catalog"."default"
);


ALTER TABLE imuser.e142_strip_transfer 
ADD CONSTRAINT uk_e142_strip_transfer_mes_sn UNIQUE (mes_sn);