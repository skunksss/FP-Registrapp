from flask import Blueprint, request, jsonify
from app import db
from app.models import Usuario
from flask_jwt_extended import create_access_token, jwt_required, get_jwt
from app.schemas import LoginSchema
from app import jwt_blacklist
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging

auth_bp = Blueprint("auth", __name__)
limiter = Limiter(key_func=get_remote_address)

@auth_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    schema = LoginSchema()
    data = request.get_json()
    ip = request.remote_addr
    logging.info(f"Intento de login desde IP {ip} con datos: {data}")

    if not data:
        logging.error(f"Login fallido: No se recibió JSON. IP: {ip}")
        return jsonify(msg="No se recibió información"), 400

    errors = schema.validate(data)
    if errors:
        logging.warning(f"Validación fallida desde IP {ip}: {errors}")
        return jsonify(errors), 400

    rut = data.get("rut")
    password = data.get("password")

    if not rut or not password:
        logging.error(f"Login fallido: Faltan campos obligatorios. IP: {ip}, Data: {data}")
        return jsonify(msg="Faltan campos obligatorios"), 400

    try:
        user = Usuario.query.filter_by(rut=rut).first()
    except Exception as e:
        logging.critical(f"Error de base de datos al buscar usuario {rut} desde IP {ip}: {e}")
        return jsonify(msg="Error interno"), 500

    if not user:
        logging.warning(f"Login fallido: Usuario no encontrado para RUT {rut} desde IP {ip}")
        return jsonify(msg="Credenciales inválidas"), 401

    if not user.check_password(password):
        logging.warning(f"Login fallido: Contraseña incorrecta para RUT {rut} desde IP {ip}")
        return jsonify(msg="Credenciales inválidas"), 401

    try:
        token = create_access_token(identity=user.id)
    except Exception as e:
        logging.critical(f"Error al crear token para usuario {rut} desde IP {ip}: {e}")
        return jsonify(msg="Error interno"), 500

    logging.info(f"Login exitoso para usuario {rut} (ID: {user.id}) desde IP {ip}")
    return jsonify(access_token=token), 200

@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    try:
        jti = get_jwt()["jti"]
        ip = request.remote_addr
        user_id = get_jwt().get("sub")
    except Exception as e:
        logging.error(f"Error obteniendo datos del JWT en logout: {e}")
        return jsonify(msg="Token inválido"), 400

    logging.info(f"Intento de logout. Usuario ID: {user_id}, IP: {ip}, JTI: {jti}")

    if jti in jwt_blacklist:
        logging.warning(f"Intento de logout con token ya revocado. Usuario ID: {user_id}, IP: {ip}")
        return jsonify(msg="Token ya revocado"), 400

    try:
        jwt_blacklist.add(jti)
    except Exception as e:
        logging.critical(f"Error al agregar JTI al blacklist en logout. Usuario ID: {user_id}, IP: {ip}, Error: {e}")
        return jsonify(msg="Error interno"), 500

    logging.info(f"Logout exitoso. Usuario ID: {user_id}, IP: {ip}")
    return jsonify(msg="Token revocado, sesión cerrada"), 200