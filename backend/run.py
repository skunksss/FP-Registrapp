from app import create_app  # importa tu app Flask ya configurada

app = create_app()          # crea una instancia de la app

if __name__ == "__main__":  # si estás ejecutando este archivo directamente...
    app.run(host="0.0.0.0", port=5000, debug=True)     # ... inicia el servidor en http://192.170.6.150:5000