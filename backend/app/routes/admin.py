from flask import Blueprint, request, jsonify
from app import db
from app.models import Usuario, Despacho, Recepcion, FotoDespacho, FotoRecepcion
from flask_jwt_extended import jwt_required, get_jwt_identity

admin_bp = Blueprint("admin", __name__)

def es_superusuario():
    usuario_actual = Usuario.query.get(get_jwt_identity())
    return usuario_actual and getattr(usuario_actual, "es_superusuario", False)

# --- Gestión de usuarios ---

@admin_bp.route("/usuarios", methods=["POST"])
@jwt_required()
def crear_usuario():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    data = request.get_json()
    usuario = Usuario(
        nombre=data.get("nombre"),
        email=data.get("email"),
        password=data.get("password"),  # Recuerda hashear la contraseña
        latitud=data.get("latitud"),
        longitud=data.get("longitud"),
        dispositivo=data.get("dispositivo"),
        es_superusuario=data.get("es_superusuario", False)
    )
    db.session.add(usuario)
    db.session.commit()
    return jsonify({"id": usuario.id}), 201

@admin_bp.route("/usuarios", methods=["GET"])
@jwt_required()
def listar_usuarios():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuarios = Usuario.query.all()
    result = []
    for u in usuarios:
        result.append({
            "id": u.id,
            "nombre": u.nombre,
            "email": u.email,
            "latitud": u.latitud,
            "longitud": u.longitud,
            "dispositivo": u.dispositivo,
            "es_superusuario": u.es_superusuario
        })
    return jsonify(result)

@admin_bp.route("/usuarios/<int:usuario_id>", methods=["PUT"])
@jwt_required()
def editar_usuario(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    data = request.get_json()
    usuario.nombre = data.get("nombre", usuario.nombre)
    usuario.email = data.get("email", usuario.email)
    usuario.latitud = data.get("latitud", usuario.latitud)
    usuario.longitud = data.get("longitud", usuario.longitud)
    usuario.es_superusuario = data.get("es_superusuario", usuario.es_superusuario)
    db.session.commit()
    return jsonify({"msg": "Usuario actualizado"})

@admin_bp.route("/usuarios/<int:usuario_id>", methods=["DELETE"])
@jwt_required()
def eliminar_usuario(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    db.session.delete(usuario)
    db.session.commit()
    return jsonify({"msg": "Usuario eliminado"})

@admin_bp.route("/usuarios/<int:usuario_id>/reset_password", methods=["POST"])
@jwt_required()
def resetear_password(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    data = request.get_json()
    usuario.password = data.get("password")  # Recuerda hashear la contraseña
    db.session.commit()
    return jsonify({"msg": "Contraseña reseteada"})

@admin_bp.route("/usuarios/<int:usuario_id>/asignar_superusuario", methods=["POST"])
@jwt_required()
def asignar_superusuario(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    usuario.es_superusuario = True
    db.session.commit()
    return jsonify({"msg": "Usuario ahora es superusuario"})

@admin_bp.route("/usuarios/<int:usuario_id>/quitar_superusuario", methods=["POST"])
@jwt_required()
def quitar_superusuario(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    usuario.es_superusuario = False
    db.session.commit()
    return jsonify({"msg": "Usuario ya no es superusuario"})

@admin_bp.route("/usuarios/<int:usuario_id>/eliminar_dispositivo", methods=["POST"])
@jwt_required()
def eliminar_dispositivo(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuario = Usuario.query.get_or_404(usuario_id)
    usuario.dispositivo = None
    db.session.commit()
    return jsonify({"msg": "Dispositivo eliminado"})

@admin_bp.route("/usuarios/dispositivos", methods=["GET"])
@jwt_required()
def listar_usuarios_con_dispositivo():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    usuarios = Usuario.query.filter(Usuario.dispositivo.isnot(None)).all()
    result = []
    for u in usuarios:
        result.append({
            "id": u.id,
            "nombre": u.nombre,
            "dispositivo": u.dispositivo
        })
    return jsonify(result)

# --- Auditoría y control ---

@admin_bp.route("/despachos", methods=["GET"])
@jwt_required()
def listar_todos_despachos():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    despachos = Despacho.query.all()
    result = []
    for d in despachos:
        result.append({
            "id": d.id,
            "numero_guia": d.numero_guia,
            "rut_empresa": d.rut_empresa,
            "usuario_id": d.usuario_id,
            "latitud": d.latitud,
            "longitud": d.longitud
        })
    return jsonify(result)

@admin_bp.route("/recepciones", methods=["GET"])
@jwt_required()
def listar_todas_recepciones():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    recepciones = Recepcion.query.all()
    result = []
    for r in recepciones:
        result.append({
            "id": r.id,
            "numero_guia": r.numero_guia,
            "rut_empresa": r.rut_empresa,
            "usuario_id": r.usuario_id,
            "latitud": r.latitud,
            "longitud": r.longitud
        })
    return jsonify(result)

@admin_bp.route("/usuarios/<int:usuario_id>/historial", methods=["GET"])
@jwt_required()
def historial_usuario(usuario_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    despachos = Despacho.query.filter_by(usuario_id=usuario_id).all()
    recepciones = Recepcion.query.filter_by(usuario_id=usuario_id).all()
    return jsonify({
        "despachos": [{"id": d.id, "numero_guia": d.numero_guia} for d in despachos],
        "recepciones": [{"id": r.id, "numero_guia": r.numero_guia} for r in recepciones]
    })

@admin_bp.route("/despachos/<int:despacho_id>", methods=["DELETE"])
@jwt_required()
def eliminar_despacho(despacho_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    despacho = Despacho.query.get_or_404(despacho_id)
    db.session.delete(despacho)
    db.session.commit()
    return jsonify({"msg": "Despacho eliminado"})

@admin_bp.route("/recepciones/<int:recepcion_id>", methods=["DELETE"])
@jwt_required()
def eliminar_recepcion(recepcion_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    recepcion = Recepcion.query.get_or_404(recepcion_id)
    db.session.delete(recepcion)
    db.session.commit()
    return jsonify({"msg": "Recepción eliminada"})

@admin_bp.route("/fotos_despacho/<int:foto_id>", methods=["DELETE"])
@jwt_required()
def eliminar_foto_despacho(foto_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    foto = FotoDespacho.query.get_or_404(foto_id)
    db.session.delete(foto)
    db.session.commit()
    return jsonify({"msg": "Foto de despacho eliminada"})

@admin_bp.route("/fotos_recepcion/<int:foto_id>", methods=["DELETE"])
@jwt_required()
def eliminar_foto_recepcion(foto_id):
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    foto = FotoRecepcion.query.get_or_404(foto_id)
    db.session.delete(foto)
    db.session.commit()
    return jsonify({"msg": "Foto de recepción eliminada"})

# --- Estadísticas ---

@admin_bp.route("/estadisticas/usuarios", methods=["GET"])
@jwt_required()
def estadisticas_usuarios():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    total = Usuario.query.count()
    activos = Usuario.query.filter(Usuario.dispositivo.isnot(None)).count()
    return jsonify({"total_usuarios": total, "usuarios_con_dispositivo": activos})

@admin_bp.route("/estadisticas/despachos", methods=["GET"])
@jwt_required()
def estadisticas_despachos():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    total = Despacho.query.count()
    return jsonify({"total_despachos": total})

@admin_bp.route("/estadisticas/recepciones", methods=["GET"])
@jwt_required()
def estadisticas_recepciones():
    if not es_superusuario():
        return jsonify({"msg": "No autorizado"}), 403
    total = Recepcion.query.count()
    return jsonify({"total_recepciones": total})