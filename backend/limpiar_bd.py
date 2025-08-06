import os
from app import create_app, db
from app.models import Despacho, Recepcion, FotoDespacho, FotoRecepcion

app = create_app()

with app.app_context():
    # Ruta absoluta a la carpeta de uploads en tu sistema
    uploads_folder = r"C:\Users\Administrador3\Desktop\backend\app\uploads"

    if os.path.exists(uploads_folder):
        archivos = os.listdir(uploads_folder)
        for archivo in archivos:
            ruta_completa = os.path.join(uploads_folder, archivo)
            if os.path.isfile(ruta_completa):
                os.remove(ruta_completa)
        print(f"✅ Archivos eliminados de: {uploads_folder}")
    else:
        print(f"❌ Carpeta no encontrada: {uploads_folder}")

    # Eliminar registros de fotos, despachos y recepciones
    FotoDespacho.query.delete()
    FotoRecepcion.query.delete()
    db.session.commit()

    Despacho.query.delete()
    Recepcion.query.delete()
    db.session.commit()

    print("✅ Todos los registros de despachos, recepciones y fotos fueron eliminados.")
