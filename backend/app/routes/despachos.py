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

    despacho = Despacho(
        numero_guia=data["numero_guia"],
        rut_empresa=data["rut_empresa"],
        usuario_id=usuario_id,
        latitud=latitud,
        longitud=longitud
    )
    db.session.add(despacho)
    db.session.commit()
    logging.info(f"Creación de despacho {despacho.id} por usuario {usuario_id} desde IP {ip} con datos: {data}, latitud: {latitud}, longitud: {longitud}")
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
            "longitud": d.longitud
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
        "longitud": d.longitud
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
        "fotos": fotos
    })

@despachos_bp.route("/<int:despacho_id>/fotos", methods=["POST"])
@jwt_required()
@limiter.limit("15 per minute")
def subir_foto_despacho(despacho_id):
    despacho = Despacho.query.get_or_404(despacho_id)
    tipo = request.form.get("tipo")
    archivo = request.files.get("archivo")
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not archivo or not tipo:
        logging.warning(f"Subida de foto fallida para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}: falta archivo o tipo")
        return jsonify({"msg": "Falta archivo o tipo"}), 400

    if not allowed_file(archivo.filename):
        logging.warning(f"Subida de foto fallida para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}: tipo de archivo no permitido ({archivo.filename})")
        return jsonify({"msg": "Tipo de archivo no permitido"}), 400

    archivo.seek(0, os.SEEK_END)
    size = archivo.tell()
    archivo.seek(0)
    if size > MAX_FILE_SIZE:
        logging.warning(f"Subida de foto fallida para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}: archivo demasiado grande ({archivo.filename}, {size} bytes)")
        return jsonify({"msg": "El archivo excede el tamaño máximo permitido (2MB)"}), 400

    uploads_folder = os.path.join(os.path.dirname(__file__), '..', 'uploads')
    uploads_folder = os.path.abspath(uploads_folder)
    if not os.path.exists(uploads_folder):
        os.makedirs(uploads_folder)

    filename = f"{tipo}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{archivo.filename}"
    ruta = os.path.join(uploads_folder, filename)
    archivo.save(ruta)

    foto = FotoDespacho(
        despacho_id=despacho.id,
        tipo=tipo,
        ruta_archivo=ruta
    )
    db.session.add(foto)
    db.session.commit()
    logging.info(f"Subida de foto '{filename}' para despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"id": foto.id, "ruta_archivo": ruta}), 201

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
    db.session.commit()
    logging.info(f"Actualización de despacho {despacho_id} por usuario {usuario_id} desde IP {ip} con nuevos datos: {data}")
    return jsonify({"msg": "Despacho actualizado"}), 200

@despachos_bp.route("/<int:despacho_id>", methods=["DELETE"])
@jwt_required()
def eliminar_despacho(despacho_id):
    despacho = Despacho.query.get_or_404(despacho_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    for foto in despacho.fotos:
        if os.path.exists(foto.ruta_archivo):
            os.remove(foto.ruta_archivo)
        db.session.delete(foto)
    db.session.delete(despacho)
    db.session.commit()
    logging.info(f"Eliminación de despacho {despacho_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"msg": "Despacho y fotos eliminados"}), 200

@despachos_bp.route("/fotos/<int:foto_id>", methods=["DELETE"])
@jwt_required()
def eliminar_foto_despacho(foto_id):
    foto = FotoDespacho.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if os.path.exists(foto.ruta_archivo):
        os.remove(foto.ruta_archivo)
    db.session.delete(foto)
    db.session.commit()
    logging.info(f"Eliminación de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"msg": "Foto eliminada"}), 200

@despachos_bp.route("/fotos/<int:foto_id>/descargar", methods=["GET"])
@jwt_required()
def descargar_foto_despacho(foto_id):
    foto = FotoDespacho.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not os.path.exists(foto.ruta_archivo):
        logging.warning(f"Descarga fallida de foto {foto_id} por usuario {usuario_id} desde IP {ip}: archivo no encontrado")
        return jsonify({"msg": "Archivo no encontrado"}), 404
    logging.info(f"Descarga de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return send_file(foto.ruta_archivo, as_attachment=True)

@despachos_bp.route("/fotos/<int:foto_id>/ver", methods=["GET"])
@jwt_required()
def ver_foto_despacho(foto_id):
    foto = FotoDespacho.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not os.path.exists(foto.ruta_archivo):
        logging.warning(f"Visualización fallida de foto {foto_id} por usuario {usuario_id} desde IP {ip}: archivo no encontrado")
        return jsonify({"msg": "Archivo no encontrado"}), 404
    logging.info(f"Visualización de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return send_file(foto.ruta_archivo)