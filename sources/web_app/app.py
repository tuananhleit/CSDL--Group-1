from flask import Flask, session
import os
import sys

# Đảm bảo thư mục web_app luôn nằm trong sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import Config
from db import init_app_tables

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Khởi tạo bảng phụ trợ nếu cần
    init_app_tables()

    @app.context_processor
    def inject_global_role():
        return {
            "current_role": session.get("role", "customer"),
            "is_logged_in": session.get("logged_in", False),
            "current_user_id": session.get("user_id"),
            "current_user_name": session.get("user_name")
        }

    from routes.auth import auth_bp
    from routes.main import main_bp
    from routes.stations import stations_bp
    from routes.bookings import bookings_bp
    from routes.sessions import sessions_bp
    from routes.billing import billing_bp
    from routes.queries import queries_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(main_bp)
    app.register_blueprint(stations_bp)
    app.register_blueprint(bookings_bp)
    app.register_blueprint(sessions_bp)
    app.register_blueprint(billing_bp)
    app.register_blueprint(queries_bp)

    return app

app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"[*] He thong Quan ly Tram sac & Bai do xe dien (Group 01) dang chay tai: http://localhost:{port}")
    app.run(host="0.0.0.0", port=port, debug=True)
