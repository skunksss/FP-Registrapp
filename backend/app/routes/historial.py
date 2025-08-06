from flask import Blueprint, request, jsonify, send_from_directory
from app.models import Despacho, Recepcion, FotoDespacho, db
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
import os
from werkzeug.utils import secure_filename

historial_bp = Blueprint("historial", __name__)

UPLOAD_FOLDER = os.path.join(os.getcwd(), "app", "uploads")
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def parse_date(date_str):
    try:
        return datetime.strptime(date_str, "%Y-%m-%d")
    except Exception:
        return None

def construir_url_archivo(nombre_archivo):
    if not nombre_archivo:
        return None
    return f"http://192.170.6.150:5000/uploads/{nombre_archivo}"

@historial_bp.route("/uploads/<path:filename>", methods=["GET"])
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@historial_bp.route("/historial/test", methods=["GET"])
def test_historial():
    return "Historial activo"

@historial_bp.route("/despachos/<int:despacho_id>/fotos", methods=["POST"])
@jwt_required()
def subir_foto_despacho(despacho_id):
    usuario_id = get_jwt_identity()
    despacho = Despacho.query.get_or_404(despacho_id)

    if 'archivo' not in request.files:
        return jsonify({"error": "Archivo no encontrado"}), 400

    file = request.files['archivo']
    tipo = request.form.get('tipo')

    if not file or not allowed_file(file.filename) or not tipo:
        return jsonify({"error": "Archivo inválido o tipo no especificado"}), 400

    filename = secure_filename(f"{datetime.utcnow().timestamp()}_{file.filename}")
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)

    nueva_foto = FotoDespacho(
        despacho_id=despacho_id,
        tipo=tipo,
        ruta_archivo=filename
    )
    db.session.add(nueva_foto)
    db.session.commit()

    return jsonify({
        "mensaje": f"Foto '{tipo}' subida correctamente",
        "archivo": filename,
        "url": construir_url_archivo(filename)
    }), 201

@historial_bp.route("/historial", methods=["GET"])
@jwt_required()
def historial_movimientos():
    usuario_id = get_jwt_identity()
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)

    rut_empresa = request.args.get('rut_empresa', '').strip()
    numero_guia = request.args.get('numero_guia', '').strip()
    fecha_inicio_str = request.args.get('fecha_inicio', '').strip()
    fecha_fin_str = request.args.get('fecha_fin', '').strip()

    fecha_inicio = parse_date(fecha_inicio_str)
    fecha_fin = parse_date(fecha_fin_str)

    # Despachos
    despachos_query = Despacho.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        despachos_query = despachos_query.filter(Despacho.rut_empresa.ilike(f"%{rut_empresa}%"))
    if numero_guia:
        despachos_query = despachos_query.filter(Despacho.numero_guia.ilike(f"%{numero_guia}%"))
    if fecha_inicio:
        despachos_query = despachos_query.filter(Despacho.fecha >= fecha_inicio)
    if fecha_fin:
        despachos_query = despachos_query.filter(Despacho.fecha <= fecha_fin)
    despachos = despachos_query.all()

    # Recepciones
    recepciones_query = Recepcion.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        recepciones_query = recepciones_query.filter(Recepcion.rut_empresa.ilike(f"%{rut_empresa}%"))
    if numero_guia:
        recepciones_query = recepciones_query.filter(Recepcion.numero_guia.ilike(f"%{numero_guia}%"))
    if fecha_inicio:
        recepciones_query = recepciones_query.filter(Recepcion.fecha >= fecha_inicio)
    if fecha_fin:
        recepciones_query = recepciones_query.filter(Recepcion.fecha <= fecha_fin)
    recepciones = recepciones_query.all()

    movimientos = [{
        "id": d.id,
        "tipo": "despacho",
        "numero_guia": d.numero_guia,
        "rut_empresa": d.rut_empresa,
        "fecha": d.fecha.isoformat(),
    } for d in despachos] + [{
        "id": r.id,
        "tipo": "recepcion",
        "numero_guia": r.numero_guia,
        "rut_empresa": r.rut_empresa,
        "fecha": r.fecha.isoformat(),
    } for r in recepciones]

    movimientos.sort(key=lambda x: x["fecha"], reverse=True)
    total = len(movimientos)
    pages = (total + per_page - 1) // per_page
    start = (page - 1) * per_page
    end = start + per_page
    movimientos_paginados = movimientos[start:end]

    return jsonify({
        "movimientos": movimientos_paginados,
        "total": total,
        "pages": pages,
        "current_page": page
    })

@historial_bp.route("/historial/despachos", methods=["GET"])
@jwt_required()
def historial_despachos():
    usuario_id = get_jwt_identity()
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)

    rut_empresa = request.args.get('rut_empresa', '').strip()
    numero_guia = request.args.get('numero_guia', '').strip()
    fecha_inicio = parse_date(request.args.get('fecha_inicio', '').strip())
    fecha_fin = parse_date(request.args.get('fecha_fin', '').strip())

    query = Despacho.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Despacho.rut_empresa.ilike(f"%{rut_empresa}%"))
    if numero_guia:
        query = query.filter(Despacho.numero_guia.ilike(f"%{numero_guia}%"))
    if fecha_inicio:
        query = query.filter(Despacho.fecha >= fecha_inicio)
    if fecha_fin:
        query = query.filter(Despacho.fecha <= fecha_fin)

    total = query.count()
    despachos = query.order_by(Despacho.fecha.desc()).paginate(page=page, per_page=per_page, error_out=False).items
    pages = (total + per_page - 1) // per_page

    return jsonify({
        "despachos": [
            {
                "id": d.id,
                "tipo": "despacho",
                "numero_guia": d.numero_guia,
                "rut_empresa": d.rut_empresa,
                "fecha": d.fecha.isoformat(),
            } for d in despachos
        ],
        "total": total,
        "pages": pages,
        "current_page": page
    })

@historial_bp.route("/historial/recepciones", methods=["GET"])
@jwt_required()
def historial_recepciones():
    usuario_id = get_jwt_identity()
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)

    rut_empresa = request.args.get('rut_empresa', '').strip()
    numero_guia = request.args.get('numero_guia', '').strip()
    fecha_inicio = parse_date(request.args.get('fecha_inicio', '').strip())
    fecha_fin = parse_date(request.args.get('fecha_fin', '').strip())

    query = Recepcion.query.filter_by(usuario_id=usuario_id)
    if rut_empresa:
        query = query.filter(Recepcion.rut_empresa.ilike(f"%{rut_empresa}%"))
    if numero_guia:
        query = query.filter(Recepcion.numero_guia.ilike(f"%{numero_guia}%"))
    if fecha_inicio:
        query = query.filter(Recepcion.fecha >= fecha_inicio)
    if fecha_fin:
        query = query.filter(Recepcion.fecha <= fecha_fin)

    total = query.count()
    recepciones = query.order_by(Recepcion.fecha.desc()).paginate(page=page, per_page=per_page, error_out=False).items
    pages = (total + per_page - 1) // per_page

    return jsonify({
        "recepciones": [
            {
                "id": r.id,
                "tipo": "recepcion",
                "numero_guia": r.numero_guia,
                "rut_empresa": r.rut_empresa,
                "fecha": r.fecha.isoformat(),
            } for r in recepciones
        ],
        "total": total,
        "pages": pages,
        "current_page": page
    })

@historial_bp.route("/detalle/despacho/<int:id>", methods=["GET"])
@jwt_required()
def detalle_despacho(id):
    despacho = Despacho.query.get_or_404(id)

    fotos_carnet = []
    fotos_patente = []
    fotos_carga = []

    for foto in despacho.fotos:
        url = construir_url_archivo(foto.ruta_archivo)
        if foto.tipo == "carnet":
            fotos_carnet.append(url)
        elif foto.tipo == "patente":
            fotos_patente.append(url)
        elif foto.tipo == "carga":
            fotos_carga.append(url)

    return jsonify({
        "rut_empresa": despacho.rut_empresa,
        "numero_guia": despacho.numero_guia,
        "fecha": despacho.fecha.isoformat(),
        "fotos_carnet_urls": fotos_carnet,
        "fotos_patente_urls": fotos_patente,
        "fotos_carga_urls": fotos_carga,
        "observacion": despacho.observacion or ""
    })

@historial_bp.route("/detalle/recepcion/<int:id>", methods=["GET"])
@jwt_required()
def detalle_recepcion(id):
    recepcion = Recepcion.query.get_or_404(id)

    fotos_carnet = []
    fotos_patente = []
    fotos_carga = []

    for foto in recepcion.fotos:
        url = construir_url_archivo(foto.ruta_archivo)
        if foto.tipo == "carnet":
            fotos_carnet.append(url)
        elif foto.tipo == "patente":
            fotos_patente.append(url)
        elif foto.tipo == "carga":
            fotos_carga.append(url)

    return jsonify({
        "rut_empresa": recepcion.rut_empresa,
        "numero_guia": recepcion.numero_guia,
        "fecha": recepcion.fecha.isoformat(),
        "fotos_carnet_urls": fotos_carnet,
        "fotos_patente_urls": fotos_patente,
        "fotos_carga_urls": fotos_carga,
        "observacion": recepcion.observacion or ""
    })
