from flask import Flask, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import Config
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
from logging.handlers import RotatingFileHandler
import os
from flasgger import Swagger
from flask_migrate import Migrate

db = SQLAlchemy()
jwt = JWTManager()
migrate = Migrate()

jwt_blacklist = set()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app, supports_credentials=True, resources={r"/*": {"origins": "*"}})

    # Configuración de Flask-Limiter
    limiter = Limiter(
        get_remote_address,
        app=app,
        default_limits=["1000 per day"]
    )

    # Configuración de logging
    logs_dir = os.path.join(os.path.dirname(__file__), '..', 'logs')
    os.makedirs(logs_dir, exist_ok=True)
    log_file = os.path.join(logs_dir, 'app_auditoria.log')

    handler = RotatingFileHandler(log_file, maxBytes=2*1024*1024, backupCount=5)
    formatter = logging.Formatter(
        '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
    )
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)

    logging.getLogger().setLevel(logging.INFO)
    logging.getLogger().addHandler(handler)

    # Inicializa Swagger
    Swagger(app)

    # Importa y registra tus rutas
    from app.routes.auth import auth_bp
    from app.routes.despachos import despachos_bp
    from app.routes.recepciones import recepciones_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(despachos_bp, url_prefix="/despachos")
    app.register_blueprint(recepciones_bp, url_prefix="/recepciones")

    # Nueva ruta: Servir archivos desde la carpeta /app/uploads
    UPLOAD_FOLDER = os.path.join(os.getcwd(), 'app', 'uploads')

    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory(UPLOAD_FOLDER, filename)

    # Configuración de revocación de tokens JWT
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload["jti"]
        return jti in jwt_blacklist

    return app
