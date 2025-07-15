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
    errors = schema.validate(data)
    ip = request.remote_addr

    if errors:
        logging.warning(f"Validación fallida desde IP {ip}: {errors}")
        return jsonify(errors), 400

    rut = data.get("rut")
    password = data.get("password")

    user = Usuario.query.filter_by(rut=rut).first()

    if not user or not user.check_password(password):
        logging.warning(f"Login fallido para RUT {rut} desde IP {ip}")
        return jsonify(msg="Credenciales inválidas"), 401

    token = create_access_token(identity=user.id)
    logging.info(f"Login exitoso para usuario {rut} desde IP {ip}")
    return jsonify(access_token=token), 200


@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    jti = get_jwt()["jti"]
    ip = request.remote_addr
    user_id = get_jwt().get("sub")

    if jti in jwt_blacklist:
        logging.warning(f"Intento de logout con token ya revocado. Usuario ID: {user_id}, IP: {ip}")
        return jsonify(msg="Token ya revocado"), 400

    jwt_blacklist.add(jti)
    logging.info(f"Logout exitoso. Usuario ID: {user_id}, IP: {ip}")
    return jsonify(msg="Token revocado, sesión cerrada"), 200
