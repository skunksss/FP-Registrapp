"""Primera migración - tablas de usuario, despacho, recepcion

Revision ID: 727535696fef
Revises: 
Create Date: 2025-07-09 12:49:46.770163

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '727535696fef'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('usuario',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('rut', sa.String(length=12), nullable=False),
    sa.Column('password_hash', sa.String(length=128), nullable=False),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('rut')
    )
    op.create_table('despacho',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('numero_guia', sa.String(length=50), nullable=False),
    sa.Column('rut_empresa', sa.String(length=12), nullable=False),
    sa.Column('fecha', sa.DateTime(), nullable=True),
    sa.Column('usuario_id', sa.Integer(), nullable=False),
    sa.Column('latitud', sa.Float(), nullable=True),
    sa.Column('longitud', sa.Float(), nullable=True),
    sa.ForeignKeyConstraint(['usuario_id'], ['usuario.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('recepcion',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('numero_guia', sa.String(length=50), nullable=False),
    sa.Column('rut_empresa', sa.String(length=12), nullable=False),
    sa.Column('fecha', sa.DateTime(), nullable=True),
    sa.Column('usuario_id', sa.Integer(), nullable=False),
    sa.Column('latitud', sa.Float(), nullable=True),
    sa.Column('longitud', sa.Float(), nullable=True),
    sa.ForeignKeyConstraint(['usuario_id'], ['usuario.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('foto_despacho',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('despacho_id', sa.Integer(), nullable=False),
    sa.Column('tipo', sa.String(length=20), nullable=False),
    sa.Column('ruta_archivo', sa.String(length=200), nullable=False),
    sa.Column('fecha_subida', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['despacho_id'], ['despacho.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('foto_recepcion',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('recepcion_id', sa.Integer(), nullable=False),
    sa.Column('tipo', sa.String(length=20), nullable=False),
    sa.Column('ruta_archivo', sa.String(length=200), nullable=False),
    sa.Column('fecha_subida', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['recepcion_id'], ['recepcion.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_table('foto_recepcion')
    op.drop_table('foto_despacho')
    op.drop_table('recepcion')
    op.drop_table('despacho')
    op.drop_table('usuario')
    # ### end Alembic commands ###
