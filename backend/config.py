import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "supersecretkey")
    SQLALCHEMY_DATABASE_URI = "sqlite:///drappdb.sqlite"
    # Para producción, puedes cambiar a una base de datos PostgreSQL o MySQL
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "jwtsecret")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=365)
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'app', 'uploads')
