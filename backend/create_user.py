# create_user.py

from app import create_app, db
from app.models import Usuario

# Crea instancia de la app
app = create_app()

# Ejecuta dentro del contexto de la app Flask
with app.app_context():
    rut = "21001625-2"
    correo = "ni.norambuena@duocuc.cl"
    password = "Admin1234"

    # Verifica si el RUT ya existe
    if Usuario.query.filter_by(rut=rut).first():
        print("El usuario ya existe")
    else:
        nuevo_usuario = Usuario(rut=rut, correo=correo)
        nuevo_usuario.set_password(password)

        db.session.add(nuevo_usuario)
        db.session.commit()
        print("Usuario creado exitosamente")
        print(f"Usuario: {nuevo_usuario.rut}, Correo: {nuevo_usuario.correo}")
