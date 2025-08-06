# manage.py

from flask.cli import FlaskGroup
from app import create_app, db
from flask_migrate import Migrate

app = create_app()
cli = FlaskGroup(app)

# Inicializa Flask-Migrate aquí también
migrate = Migrate(app, db)

if __name__ == "__main__":
    cli()
