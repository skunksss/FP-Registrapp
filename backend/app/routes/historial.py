from flask import Blueprint, request, jsonify
from app.models import Despacho, Recepcion
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import logging

historial_bp = Blueprint("historial", __name__)

def parse_date(date_str):
    try:
        return datetime.strptime(date_str, "%Y-%m-%d")
    except Exception:
        return None

# Endpoint combinado: todos los movimientos
@historial_bp.route("/", methods=["GET"])
@jwt_required()
def historial_movimientos():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    rut_empresa = request.args.get('rut_empresa')
    numero_guia = request.args.get('numero_guia')
    fecha_inicio = parse_date(request.args.get('fecha_inicio', ''))
    fecha_fin = parse_date(request.args.get('fecha_fin', ''))

    # Log de consulta general y filtros
    filtros = {
        "rut_empresa": rut_empresa,
        "numero_guia": numero_guia,
        "fecha_inicio": request.args.get('fecha_inicio', ''),
        "fecha_fin": request.args.get('fecha_fin', '')
    }
    logging.info(f"Consulta de historial combinado por usuario {usuario_id} desde IP {ip} - página {page}, por página {per_page}, filtros: {filtros}")

    # Filtros para despachos
    despachos_query = Despacho.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        despachos_query = despachos_query.filter(Despacho.rut_empresa == rut_empresa)
    if numero_guia:
        despachos_query = despachos_query.filter(Despacho.numero_guia == numero_guia)
    if fecha_inicio:
        despachos_query = despachos_query.filter(Despacho.fecha >= fecha_inicio)
    if fecha_fin:
        despachos_query = despachos_query.filter(Despacho.fecha <= fecha_fin)
    despachos = despachos_query.all()

    # Filtros para recepciones
    recepciones_query = Recepcion.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        recepciones_query = recepciones_query.filter(Recepcion.rut_empresa == rut_empresa)
    if numero_guia:
        recepciones_query = recepciones_query.filter(Recepcion.numero_guia == numero_guia)
    if fecha_inicio:
        recepciones_query = recepciones_query.filter(Recepcion.fecha >= fecha_inicio)
    if fecha_fin:
        recepciones_query = recepciones_query.filter(Recepcion.fecha <= fecha_fin)
    recepciones = recepciones_query.all()

    # Unir y ordenar por fecha descendente
    movimientos = []
    for d in despachos:
        movimientos.append({
            "id": d.id,
            "tipo": "despacho",
            "numero_guia": d.numero_guia,
            "rut_empresa": d.rut_empresa,
            "fecha": d.fecha,
        })
    for r in recepciones:
        movimientos.append({
            "id": r.id,
            "tipo": "recepcion",
            "numero_guia": r.numero_guia,
            "rut_empresa": r.rut_empresa,
            "fecha": r.fecha,
        })
    movimientos.sort(key=lambda x: x["fecha"], reverse=True)

    # Paginación manual
    total = len(movimientos)
    start = (page - 1) * per_page
    end = start + per_page
    movimientos_paginados = movimientos[start:end]

    # Log de paginación
    logging.info(f"Usuario {usuario_id} desde IP {ip} accede a página {page} de historial combinado (movimientos totales: {total})")

    return jsonify({
        "movimientos": movimientos_paginados,
        "total": total,
        "pages": (total + per_page - 1) // per_page,
        "current_page": page
    })

# Endpoint solo para despachos
@historial_bp.route("/despachos", methods=["GET"])
@jwt_required()
def historial_despachos():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    rut_empresa = request.args.get('rut_empresa')
    numero_guia = request.args.get('numero_guia')
    fecha_inicio = parse_date(request.args.get('fecha_inicio', ''))
    fecha_fin = parse_date(request.args.get('fecha_fin', ''))

    filtros = {
        "rut_empresa": rut_empresa,
        "numero_guia": numero_guia,
        "fecha_inicio": request.args.get('fecha_inicio', ''),
        "fecha_fin": request.args.get('fecha_fin', '')
    }
    logging.info(f"Consulta de historial de despachos por usuario {usuario_id} desde IP {ip} - página {page}, por página {per_page}, filtros: {filtros}")

    query = Despacho.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Despacho.rut_empresa == rut_empresa)
    if numero_guia:
        query = query.filter(Despacho.numero_guia == numero_guia)
    if fecha_inicio:
        query = query.filter(Despacho.fecha >= fecha_inicio)
    if fecha_fin:
        query = query.filter(Despacho.fecha <= fecha_fin)
    query = query.order_by(Despacho.fecha.desc())
    despachos = query.paginate(page=page, per_page=per_page)

    result = [{
        "id": d.id,
        "numero_guia": d.numero_guia,
        "rut_empresa": d.rut_empresa,
        "fecha": d.fecha,
        "usuario_id": d.usuario_id
    } for d in despachos.items]

    # Log de paginación
    logging.info(f"Usuario {usuario_id} desde IP {ip} accede a página {page} de historial de despachos (total: {despachos.total})")

    return jsonify({
        "despachos": result,
        "total": despachos.total,
        "pages": despachos.pages,
        "current_page": despachos.page
    })

# Endpoint solo para recepciones
@historial_bp.route("/recepciones", methods=["GET"])
@jwt_required()
def historial_recepciones():
    usuario_id = get_jwt_identity()
    ip = request.remote_addr
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    rut_empresa = request.args.get('rut_empresa')
    numero_guia = request.args.get('numero_guia')
    fecha_inicio = parse_date(request.args.get('fecha_inicio', ''))
    fecha_fin = parse_date(request.args.get('fecha_fin', ''))

    filtros = {
        "rut_empresa": rut_empresa,
        "numero_guia": numero_guia,
        "fecha_inicio": request.args.get('fecha_inicio', ''),
        "fecha_fin": request.args.get('fecha_fin', '')
    }
    logging.info(f"Consulta de historial de recepciones por usuario {usuario_id} desde IP {ip} - página {page}, por página {per_page}, filtros: {filtros}")

    query = Recepcion.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Recepcion.rut_empresa == rut_empresa)
    if numero_guia:
        query = query.filter(Recepcion.numero_guia == numero_guia)
    if fecha_inicio:
        query = query.filter(Recepcion.fecha >= fecha_inicio)
    if fecha_fin:
        query = query.filter(Recepcion.fecha <= fecha_fin)
    query = query.order_by(Recepcion.fecha.desc())
    recepciones = query.paginate(page=page, per_page=per_page)

    result = [{
        "id": r.id,
        "numero_guia": r.numero_guia,
        "rut_empresa": r.rut_empresa,
        "fecha": r.fecha,
        "usuario_id": r.usuario_id
    } for r in recepciones.items]

    # Log de paginación
    logging.info(f"Usuario {usuario_id} desde IP {ip} accede a página {page} de historial de recepciones (total: {recepciones.total})")

    return jsonify({
        "recepciones": result,
        "total": recepciones.total,
        "pages": recepciones.pages,
        "current_page": recepciones.page
    })