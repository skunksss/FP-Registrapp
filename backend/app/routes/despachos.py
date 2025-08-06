from flask import Blueprint, request, jsonify, send_file
from app import db
from app.models import Despacho, FotoDespacho
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import os
from app.schemas import DespachoSchema
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
from werkzeug.utils import secure_filename

despachos_bp = Blueprint("despachos", __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_FILE_SIZE = 2 * 1024 * 1024  # 2 MB

limiter = Limiter(key_func=get_remote_address)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@despachos_bp.route("/", methods=["POST"])
@jwt_required()
@limiter.limit("20 per minute")
def crear_despacho():
    schema = DespachoSchema()
    data = request.form.to_dict()
    errors = schema.validate(data)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr

    if errors:
        logging.warning(f"Creación de despacho fallida por usuario {usuario_id} desde IP {ip}: errores {errors}")
        return jsonify(errors), 400

    latitud = request.form.get("latitud", type=float)
    longitud = request.form.get("longitud", type=float)
    observacion = data.get("observacion")

    despacho = Despacho(
        numero_guia=data["numero_guia"],
        rut_empresa=data["rut_empresa"],
        usuario_id=usuario_id,
        latitud=latitud,
        longitud=longitud,
        observacion=observacion
    )
    db.session.add(despacho)
    db.session.commit()
    logging.info(f"Creación de despacho {despacho.id} por usuario {usuario_id} desde IP {ip} con datos: {data}, latitud: {latitud}, longitud: {longitud}, observacion: {observacion}")
    return jsonify({"id": despacho.id}), 201

@despachos_bp.route("/", methods=["GET"])
@jwt_required()
def listar_despachos():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    despachos = Despacho.query.all()
    result = []
    for d in despachos:
        result.append({
            "id": d.id,
            "numero_guia": d.numero_guia,
            "rut_empresa": d.rut_empresa,
            "fecha": d.fecha,
            "usuario_id": d.usuario_id,
            "latitud": d.latitud,
            "longitud": d.longitud,
            "observacion": d.observacion
        })
    logging.info(f"Listado de despachos solicitado por usuario {usuario_id} desde IP {ip}. Total: {len(result)}")
    return jsonify(result)

@despachos_bp.route("/historial", methods=["GET"])
@jwt_required()
def historial_despachos():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    rut_empresa = request.args.get('rut_empresa')
    numero_guia = request.args.get('numero_guia')
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')

    query = Despacho.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Despacho.rut_empresa == rut_empresa)
    if numero_guia:
        query = query.filter(Despacho.numero_guia == numero_guia)
    if fecha_inicio:
        try:
            fecha_inicio_dt = datetime.strptime(fecha_inicio, "%Y-%m-%d")
            query = query.filter(Despacho.fecha >= fecha_inicio_dt)
        except Exception as e:
            logging.warning(f"Error parseando fecha_inicio: {fecha_inicio} - {e}")
    if fecha_fin:
        try:
            fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
            query = query.filter(Despacho.fecha <= fecha_fin_dt)
        except Exception as e:
            logging.warning(f"Error parseando fecha_fin: {fecha_fin} - {e}")

    despachos = query.order_by(Despacho.fecha.desc()).paginate(page=page, per_page=per_page)
    result = [{
        "id": d.id,
        "numero_guia": d.numero_guia,
        "rut_empresa": d.rut_empresa,
        "fecha": d.fecha,
        "usuario_id": d.usuario_id,
        "latitud": d.latitud,
        "longitud": d.longitud,
        "observacion": d.observacion
    } for d in despachos.items]
    logging.info(f"Historial de despachos solicitado por usuario {usuario_id} desde IP {ip}. Página: {page}, Total: {despachos.total}")
    return jsonify({
        "despachos": result,
        "total": despachos.total,
        "pages": despachos.pages,
        "current_page": despachos.page
    })

@despachos_bp.route("/<int:despacho_id>", methods=["GET"])
@jwt_required()
def detalle_despacho(despacho_id):
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    despacho = Despacho.query.get_or_404(despacho_id)
    fotos = [
        {"id": f.id, "tipo": f.tipo, "ruta_archivo": f.ruta_archivo}
        for f in despacho.fotos
    ]
    logging.info(f"Detalle de despacho {despacho_id} solicitado por usuario {usuario_id} desde IP {ip}")
    return jsonify({
        "id": despacho.id,
        "numero_guia": despacho.numero_guia,
        "rut_empresa": despacho.rut_empresa,
        "fecha": despacho.fecha,
        "usuario_id": despacho.usuario_id,
        "latitud": despacho.latitud,
        "longitud": despacho.longitud,
        "observacion": despacho.observacion,
        "fotos": fotos
    })

@despachos_bp.route("/<int:despacho_id>/fotos", methods=["POST"])
@jwt_required()
@limiter.limit("15 per minute")
def subir_fotos_despacho(despacho_id):
    despacho = Despacho.query.get_or_404(despacho_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr

    tipo = request.form.get("tipo")
    archivos = request.files.getlist("archivo")

    if not tipo or not archivos:
        logging.warning(f"Falta tipo o archivos para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
        return jsonify({"msg": "Falta el tipo o los archivos"}), 400

    if tipo not in ['carnet', 'patente', 'carga']:
        logging.warning(f"Tipo inválido '{tipo}' para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
        return jsonify({"msg": "Tipo de foto inválido"}), 400

    uploads_folder = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'uploads'))
    os.makedirs(uploads_folder, exist_ok=True)

    fotos_guardadas = []

    for archivo in archivos:
        if not allowed_file(archivo.filename):
            logging.warning(f"Archivo no permitido para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
            continue

        archivo.seek(0, os.SEEK_END)
        size = archivo.tell()
        archivo.seek(0)
        if size > MAX_FILE_SIZE:
            logging.warning(f"Archivo excede tamaño en despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
            continue

        filename = secure_filename(f"{tipo}_{datetime.utcnow().strftime('%Y%m%d%H%M%S%f')}_{archivo.filename}")
        ruta = os.path.join(uploads_folder, filename)
        archivo.save(ruta)

        foto = FotoDespacho(
            despacho_id=despacho.id,
            tipo=tipo,
            ruta_archivo=filename
        )
        db.session.add(foto)
        fotos_guardadas.append({
            "id": foto.id,
            "tipo": tipo,
            "ruta_archivo": filename
        })

    db.session.commit()
    logging.info(f"{len(fotos_guardadas)} fotos subidas para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
    
    return jsonify({"fotos": fotos_guardadas}), 201

@despachos_bp.route("/<int:despacho_id>", methods=["PUT"])
@jwt_required()
def actualizar_despacho(despacho_id):
    schema = DespachoSchema()
    data = request.form.to_dict()
    errors = schema.validate(data)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if errors:
        logging.warning(f"Actualización fallida de despacho {despacho_id} por usuario {usuario_id} desde IP {ip}: errores {errors}")
        return jsonify(errors), 400

    despacho = Despacho.query.get_or_404(despacho_id)
    despacho.numero_guia = data["numero_guia"]
    despacho.rut_empresa = data["rut_empresa"]
    despacho.latitud = request.form.get("latitud", type=float)
    despacho.longitud = request.form.get("longitud", type=float)
    despacho.observacion = data.get("observacion")
    db.session.commit()
    logging.info(f"Actualización de despacho {despacho_id} por usuario {usuario_id} desde IP {ip} con nuevos datos: {data}")
    return jsonify({"msg": "Despacho actualizado"}), 200
