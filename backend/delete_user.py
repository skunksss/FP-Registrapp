# delete_user.py

from app import create_app, db
from app.models import Usuario

app = create_app()

with app.app_context():
    rut = "21001625-2"  # Cambia esto por el RUT del usuario que quieres eliminar

    usuario = Usuario.query.filter_by(rut=rut).first()

    if usuario:
        db.session.delete(usuario)
        db.session.commit()
        print(f"Usuario con RUT {rut} eliminado correctamente")
    else:
        print(f"No se encontró un usuario con RUT {rut}")
