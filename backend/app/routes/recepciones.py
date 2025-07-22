from flask import Blueprint, request, jsonify, send_file
from app import db
from app.models import Recepcion, FotoRecepcion
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import os
from app.schemas import RecepcionSchema
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging

recepciones_bp = Blueprint("recepciones", __name__)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_FILE_SIZE = 2 * 1024 * 1024  # 2 MB

limiter = Limiter(key_func=get_remote_address)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@recepciones_bp.route("/", methods=["POST"])
@jwt_required()
@limiter.limit("20 per minute")
def crear_recepcion():
    schema = RecepcionSchema()
    data = request.form.to_dict()
    errors = schema.validate(data)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if errors:
        logging.warning(f"Creación de recepción fallida por usuario {usuario_id} desde IP {ip}: errores {errors}")
        return jsonify(errors), 400

    latitud = request.form.get("latitud", type=float)
    longitud = request.form.get("longitud", type=float)

    recepcion = Recepcion(
        numero_guia=data["numero_guia"],
        rut_empresa=data["rut_empresa"],
        usuario_id=usuario_id,
        latitud=latitud,
        longitud=longitud
    )
    db.session.add(recepcion)
    db.session.commit()
    logging.info(f"Creación de recepción {recepcion.id} por usuario {usuario_id} desde IP {ip} con datos: {data}, latitud: {latitud}, longitud: {longitud}")
    return jsonify({"id": recepcion.id}), 201

@recepciones_bp.route("/", methods=["GET"])
@jwt_required()
def listar_recepciones():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    recepciones = Recepcion.query.all()
    result = []
    for r in recepciones:
        result.append({
            "id": r.id,
            "numero_guia": r.numero_guia,
            "rut_empresa": r.rut_empresa,
            "fecha": r.fecha,
            "usuario_id": r.usuario_id,
            "latitud": r.latitud,
            "longitud": r.longitud
        })
    logging.info(f"Listado de recepciones solicitado por usuario {usuario_id} desde IP {ip}. Total: {len(result)}")
    return jsonify(result)

@recepciones_bp.route("/historial", methods=["GET"])
@jwt_required()
def historial_recepciones():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    rut_empresa = request.args.get('rut_empresa')
    numero_guia = request.args.get('numero_guia')
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')

    query = Recepcion.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Recepcion.rut_empresa == rut_empresa)
    if numero_guia:
        query = query.filter(Recepcion.numero_guia == numero_guia)
    if fecha_inicio:
        try:
            fecha_inicio_dt = datetime.strptime(fecha_inicio, "%Y-%m-%d")
            query = query.filter(Recepcion.fecha >= fecha_inicio_dt)
        except Exception as e:
            logging.warning(f"Error parseando fecha_inicio: {fecha_inicio} - {e}")
    if fecha_fin:
        try:
            fecha_fin_dt = datetime.strptime(fecha_fin, "%Y-%m-%d")
            query = query.filter(Recepcion.fecha <= fecha_fin_dt)
        except Exception as e:
            logging.warning(f"Error parseando fecha_fin: {fecha_fin} - {e}")

    recepciones = query.order_by(Recepcion.fecha.desc()).paginate(page=page, per_page=per_page)
    result = [{
        "id": r.id,
        "numero_guia": r.numero_guia,
        "rut_empresa": r.rut_empresa,
        "fecha": r.fecha,
        "usuario_id": r.usuario_id,
        "latitud": r.latitud,
        "longitud": r.longitud
    } for r in recepciones.items]
    logging.info(f"Historial de recepciones solicitado por usuario {usuario_id} desde IP {ip}. Página: {page}, Total: {recepciones.total}")
    return jsonify({
        "recepciones": result,
        "total": recepciones.total,
        "pages": recepciones.pages,
        "current_page": recepciones.page
    })

@recepciones_bp.route("/<int:recepcion_id>", methods=["GET"])
@jwt_required()
def detalle_recepcion(recepcion_id):
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    recepcion = Recepcion.query.get_or_404(recepcion_id)
    fotos = [
        {"id": f.id, "tipo": f.tipo, "ruta_archivo": f.ruta_archivo}
        for f in recepcion.fotos
    ]
    logging.info(f"Detalle de recepción {recepcion_id} solicitado por usuario {usuario_id} desde IP {ip}")
    return jsonify({
        "id": recepcion.id,
        "numero_guia": recepcion.numero_guia,
        "rut_empresa": recepcion.rut_empresa,
        "fecha": recepcion.fecha,
        "usuario_id": recepcion.usuario_id,
        "latitud": recepcion.latitud,
        "longitud": recepcion.longitud,
        "fotos": fotos
    })

@recepciones_bp.route("/<int:recepcion_id>/fotos", methods=["POST"])
@jwt_required()
@limiter.limit("15 per minute")
def subir_foto_recepcion(recepcion_id):
    recepcion = Recepcion.query.get_or_404(recepcion_id)
    tipo = request.form.get("tipo")
    archivo = request.files.get("archivo")
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not archivo or not tipo:
        logging.warning(f"Subida de foto fallida para recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}: falta archivo o tipo")
        return jsonify({"msg": "Falta archivo o tipo"}), 400

    if not allowed_file(archivo.filename):
        logging.warning(f"Subida de foto fallida para recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}: tipo de archivo no permitido ({archivo.filename})")
        return jsonify({"msg": "Tipo de archivo no permitido"}), 400

    archivo.seek(0, os.SEEK_END)
    size = archivo.tell()
    archivo.seek(0)
    if size > MAX_FILE_SIZE:
        logging.warning(f"Subida de foto fallida para recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}: archivo demasiado grande ({archivo.filename}, {size} bytes)")
        return jsonify({"msg": "El archivo excede el tamaño máximo permitido (2MB)"}), 400

    uploads_folder = os.path.join(os.path.dirname(__file__), '..', 'uploads')
    uploads_folder = os.path.abspath(uploads_folder)
    if not os.path.exists(uploads_folder):
        os.makedirs(uploads_folder)

    filename = f"{tipo}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{archivo.filename}"
    ruta = os.path.join(uploads_folder, filename)
    archivo.save(ruta)

    foto = FotoRecepcion(
        recepcion_id=recepcion.id,
        tipo=tipo,
        ruta_archivo=ruta
    )
    db.session.add(foto)
    db.session.commit()
    logging.info(f"Subida de foto '{filename}' para recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"id": foto.id, "ruta_archivo": ruta}), 201

@recepciones_bp.route("/<int:recepcion_id>", methods=["PUT"])
@jwt_required()
def actualizar_recepcion(recepcion_id):
    schema = RecepcionSchema()
    data = request.form.to_dict()
    errors = schema.validate(data)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if errors:
        logging.warning(f"Actualización fallida de recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}: errores {errors}")
        return jsonify(errors), 400

    recepcion = Recepcion.query.get_or_404(recepcion_id)
    recepcion.numero_guia = data["numero_guia"]
    recepcion.rut_empresa = data["rut_empresa"]
    recepcion.latitud = request.form.get("latitud", type=float)
    recepcion.longitud = request.form.get("longitud", type=float)
    db.session.commit()
    logging.info(f"Actualización de recepción {recepcion_id} por usuario {usuario_id} desde IP {ip} con nuevos datos: {data}")
    return jsonify({"msg": "Recepción actualizada"}), 200

@recepciones_bp.route("/<int:recepcion_id>", methods=["DELETE"])
@jwt_required()
def eliminar_recepcion(recepcion_id):
    recepcion = Recepcion.query.get_or_404(recepcion_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    for foto in recepcion.fotos:
        if os.path.exists(foto.ruta_archivo):
            os.remove(foto.ruta_archivo)
        db.session.delete(foto)
    db.session.delete(recepcion)
    db.session.commit()
    logging.info(f"Eliminación de recepción {recepcion_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"msg": "Recepción y fotos eliminadas"}), 200

@recepciones_bp.route("/fotos/<int:foto_id>", methods=["DELETE"])
@jwt_required()
def eliminar_foto_recepcion(foto_id):
    foto = FotoRecepcion.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if os.path.exists(foto.ruta_archivo):
        os.remove(foto.ruta_archivo)
    db.session.delete(foto)
    db.session.commit()
    logging.info(f"Eliminación de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return jsonify({"msg": "Foto eliminada"}), 200

@recepciones_bp.route("/fotos/<int:foto_id>/descargar", methods=["GET"])
@jwt_required()
def descargar_foto_recepcion(foto_id):
    foto = FotoRecepcion.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not os.path.exists(foto.ruta_archivo):
        logging.warning(f"Descarga fallida de foto {foto_id} por usuario {usuario_id} desde IP {ip}: archivo no encontrado")
        return jsonify({"msg": "Archivo no encontrado"}), 404
    logging.info(f"Descarga de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return send_file(foto.ruta_archivo, as_attachment=True)

@recepciones_bp.route("/fotos/<int:foto_id>/ver", methods=["GET"])
@jwt_required()
def ver_foto_recepcion(foto_id):
    foto = FotoRecepcion.query.get_or_404(foto_id)
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    if not os.path.exists(foto.ruta_archivo):
        logging.warning(f"Visualización fallida de foto {foto_id} por usuario {usuario_id} desde IP {ip}: archivo no encontrado")
        return jsonify({"msg": "Archivo no encontrado"}), 404
    logging.info(f"Visualización de foto {foto_id} por usuario {usuario_id} desde IP {ip}")
    return send_file(foto.ruta_archivo)