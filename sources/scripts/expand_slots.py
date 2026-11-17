# sources/scripts/expand_slots.py
import os
import sys

# Ensure web_app is in path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'web_app'))

plan = [
    ('T01', 'A', 6, 20, 2, 6),
    ('T02', 'B', 5, 28, 2, 8),
    ('T03', 'C', 4, 30, 1, 10),
    ('T04', 'A', 9, 25, 3, 7),
    ('T05', 'A', 9, 22, 3, 6),
    ('T06', 'A', 9, 20, 3, 5),
    ('T07', 'A', 9, 24, 3, 6),
    ('T08', 'A', 9, 18, 3, 5),
    ('T09', 'A', 9, 26, 3, 7)
]

slots = []
poles = []

cur_cho_id = 161
cur_tru_id = 143

pole_types_car = ['LT04', 'LT03', 'LT02', None]
pole_types_moto = ['LT05', 'LT05', None]

for tram, pfx, c_start, c_end, m_start, m_end in plan:
    for i in range(c_start, c_end + 1):
        cho_code = f"CHO{cur_cho_id}"
        vi_tri = f"{pfx}-{i:02d}"
        mota = f"Khu {pfx} - Vi tri {vi_tri}"
        ptype = pole_types_car[(i - c_start) % len(pole_types_car)]
        slots.append((cho_code, tram, vi_tri, 'CarSlot', mota, 'Available'))
        if ptype:
            tru_code = f"TS{cur_tru_id}"
            poles.append((tru_code, cho_code, ptype, 'Available'))
            cur_tru_id += 1
        cur_cho_id += 1
        
    for j in range(m_start, m_end + 1):
        cho_code = f"CHO{cur_cho_id}"
        vi_tri = f"M-{j:02d}"
        mota = f"Khu xe may M - Vi tri {vi_tri}"
        ptype = pole_types_moto[(j - m_start) % len(pole_types_moto)]
        slots.append((cho_code, tram, vi_tri, 'MotorbikeSlot', mota, 'Available'))
        if ptype:
            tru_code = f"TS{cur_tru_id}"
            poles.append((tru_code, cho_code, ptype, 'Available'))
            cur_tru_id += 1
        cur_cho_id += 1

# Generate SQL for CHO_DO_XE
sql_cho = "\n-- Mo rong suc chua: Moi tram tu 20 den 40 cho do\nINSERT INTO CHO_DO_XE (MaCho, MaTram, MaViTri, LoaiCho, MoTaViTri, TrangThaiCho) VALUES\n"
cho_rows = [f"('{s[0]}', '{s[1]}', '{s[2]}', '{s[3]}', '{s[4]}', '{s[5]}')" for s in slots]
sql_cho += ",\n".join(cho_rows) + ";\n"

cho_file = os.path.join(os.path.dirname(__file__), '..', 'database', 'table', '05_CHO_DO_XE.sql')
with open(cho_file, 'a', encoding='utf-8') as f:
    f.write(sql_cho)

# Generate SQL for TRU_SAC
sql_tru = "\n-- Mo rong tru sac tuong ung cho cac o do moi mo rong\nINSERT INTO TRU_SAC (MaTru, MaCho, MaLoaiTru, TrangThaiTru, NgayLapDat) VALUES\n"
tru_rows = [f"('{p[0]}', '{p[1]}', '{p[2]}', '{p[3]}', '2026-02-01')" for p in poles]
sql_tru += ",\n".join(tru_rows) + ";\n"

tru_file = os.path.join(os.path.dirname(__file__), '..', 'database', 'table', '07_TRU_SAC.sql')
with open(tru_file, 'a', encoding='utf-8') as f:
    f.write(sql_tru)

print(f"Successfully appended {len(slots)} slots and {len(poles)} poles to SQL table files!")
