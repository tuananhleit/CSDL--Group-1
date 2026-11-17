import mysql.connector
from mysql.connector import Error
from config import Config

def get_db_connection():
    """Tạo kết nối đến MySQL Server."""
    return mysql.connector.connect(
        host=Config.MYSQL_HOST,
        port=Config.MYSQL_PORT,
        user=Config.MYSQL_USER,
        password=Config.MYSQL_PASSWORD,
        database=Config.MYSQL_DATABASE,
        charset="utf8mb4",
        collation="utf8mb4_unicode_ci",
        autocommit=False
    )

def test_connection():
    """Kiểm tra trạng thái kết nối đến MySQL."""
    try:
        conn = get_db_connection()
        if conn.is_connected():
            cursor = conn.cursor()
            cursor.execute("SELECT VERSION(), DATABASE();")
            ver, db = cursor.fetchone()
            cursor.close()
            conn.close()
            return True, f"Kết nối thành công (MySQL {ver}, DB: {db})"
    except Error as e:
        return False, str(e)
    return False, "Không thể kết nối"

def query_all(sql, params=None):
    """Thực thi câu lệnh SELECT và trả về danh sách dict."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        rows = cursor.fetchall()
        cursor.close()
        return rows
    finally:
        conn.close()

def query_one(sql, params=None):
    """Thực thi câu lệnh SELECT và trả về 1 dict."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        row = cursor.fetchone()
        cursor.close()
        return row
    finally:
        conn.close()

def execute_statement(sql, params=None, commit=True):
    """Thực thi câu lệnh INSERT/UPDATE/DELETE."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(sql, params or ())
        if commit:
            conn.commit()
        last_id = cursor.lastrowid
        row_count = cursor.rowcount
        cursor.close()
        return {"rowcount": row_count, "lastrowid": last_id}
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def call_procedure(proc_name, args=()):
    """Gọi một Stored Procedure trong MySQL."""
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        result_args = cursor.callproc(proc_name, args)
        conn.commit()
        cursor.close()
        return result_args
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
