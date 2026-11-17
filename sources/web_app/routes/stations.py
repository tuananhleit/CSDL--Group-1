from flask import Blueprint, render_template, request
from db import test_connection, query_all

stations_bp = Blueprint("stations", __name__)

@stations_bp.route("/stations")
def list_stations():
    db_ok, db_msg = test_connection()
    stations = []
    available_slots = []
    selected_tram = request.args.get("tram", "")
    
    if db_ok:
        try:
            stations = query_all("SELECT MaTram, TenTram, DiaChi, SoDuToiThieu, PhutAnHanSauSac FROM TRAM ORDER BY MaTram")
            
            sql = """
                SELECT MaTram, TenTram, MaCho, MaViTri, LoaiCho, MoTaViTri,
                       MaTru, LoaiTru, ChuanKetNoi, CongSuat_kW, TinhTrangSac
                FROM VW_CHO_DO_TRONG
            """
            params = []
            if selected_tram:
                sql += " WHERE MaTram = %s"
                params.append(selected_tram)
            sql += " ORDER BY MaTram, MaViTri"
            
            available_slots = query_all(sql, params)
        except Exception as e:
            db_msg = str(e)
            
    return render_template("stations.html", db_ok=db_ok, db_msg=db_msg,
                           stations=stations, available_slots=available_slots,
                           selected_tram=selected_tram)
