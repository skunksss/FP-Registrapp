# create_user.py

from app import create_app, db
from app.models import Usuario

# Crea instancia de la app
app = create_app()

# Ejecuta dentro del contexto de la app Flask
with app.app_context():
    rut = "19.100.681-K"
    correo = "rsilva@fpetricio.cl"
    password = "admin1234"
    nombre = "Raul Silva"
    cargo = "Asistente de soporte informatico"
    tipo_usuario = "admin" 

    # Verifica si el RUT ya existe
    if Usuario.query.filter_by(rut=rut).first():
        print("El usuario ya existe")
    else:
        nuevo_usuario = Usuario(
            rut=rut,
            correo=correo,
            nombre=nombre,
            cargo=cargo,
            tipo_usuario=tipo_usuario
        )
        nuevo_usuario.set_password(password)

        db.session.add(nuevo_usuario)
        db.session.commit()
        print("Usuario creado exitosamente")
        print(f"Usuario: {nuevo_usuario.nombre}, Cargo: {nuevo_usuario.cargo}, Tipo: {nuevo_usuario.tipo_usuario}")
