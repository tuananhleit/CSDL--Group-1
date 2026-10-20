USE smart_ev_parking;

CREATE ROLE IF NOT EXISTS 'app_user_role', 'station_operator_role', 'sys_admin_role';

GRANT SELECT ON smart_ev_parking.TRAM TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.CHO_DO_XE TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.LOAI_TRU_SAC TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.TRU_SAC TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.BANG_GIA TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.KHACH_HANG TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.PHUONG_TIEN TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.HOA_DON TO 'app_user_role';
GRANT SELECT ON smart_ev_parking.GIAO_DICH_VI TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.DAT_CHO TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.PHIEN TO 'app_user_role';
GRANT SELECT, INSERT ON smart_ev_parking.CHI_TIET_PHIEN_SAC TO 'app_user_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_thanh_toan_hoa_don_vi TO 'app_user_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_kiem_tra_va_ngat_sac_tu_dong TO 'app_user_role';

GRANT SELECT, UPDATE ON smart_ev_parking.CHO_DO_XE TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.TRU_SAC TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.PHUONG_TIEN TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.HOA_DON TO 'station_operator_role';
GRANT SELECT, UPDATE ON smart_ev_parking.PHIEN TO 'station_operator_role';
GRANT SELECT, INSERT, UPDATE ON smart_ev_parking.BANG_GIA TO 'station_operator_role';
GRANT SELECT ON smart_ev_parking.KHACH_HANG TO 'station_operator_role';
GRANT SELECT ON smart_ev_parking.GIAO_DICH_VI TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_thanh_toan_walkin_ngoai TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_xu_ly_dat_cho_qua_han TO 'station_operator_role';
GRANT EXECUTE ON PROCEDURE smart_ev_parking.sp_kiem_tra_va_ngat_sac_tu_dong TO 'station_operator_role';

GRANT ALL PRIVILEGES ON smart_ev_parking.* TO 'sys_admin_role';
