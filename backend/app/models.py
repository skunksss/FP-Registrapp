from app import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

class Usuario(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    rut = db.Column(db.String(12), unique=True, nullable=False)
    correo = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Despacho(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    numero_guia = db.Column(db.String(50), nullable=False)
    rut_empresa = db.Column(db.String(12), nullable=False)
    fecha = db.Column(db.DateTime, default=datetime.utcnow)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuario.id"), nullable=False)
    fotos = db.relationship('FotoDespacho', backref='despacho', lazy=True)
    latitud = db.Column(db.Float) 
    longitud = db.Column(db.Float)

class FotoDespacho(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    despacho_id = db.Column(db.Integer, db.ForeignKey('despacho.id'), nullable=False)
    tipo = db.Column(db.String(20), nullable=False)  # carnet, patente, carga
    ruta_archivo = db.Column(db.String(200), nullable=False)
    fecha_subida = db.Column(db.DateTime, default=datetime.utcnow)

class Recepcion(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    numero_guia = db.Column(db.String(50), nullable=False)
    rut_empresa = db.Column(db.String(12), nullable=False)
    fecha = db.Column(db.DateTime, default=datetime.utcnow)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuario.id"), nullable=False)
    fotos = db.relationship('FotoRecepcion', backref='recepcion', lazy=True)
    latitud = db.Column(db.Float)  
    longitud = db.Column(db.Float)  

class FotoRecepcion(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    recepcion_id = db.Column(db.Integer, db.ForeignKey('recepcion.id'), nullable=False)
    tipo = db.Column(db.String(20), nullable=False)  # carnet, patente, carga
    ruta_archivo = db.Column(db.String(200), nullable=False)
    fecha_subida = db.Column(db.DateTime, default=datetime.utcnow)