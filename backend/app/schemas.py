from flask_marshmallow import Marshmallow
from marshmallow import fields, validate, ValidationError

ma = Marshmallow()

def validar_rut_chileno(rut):
    """
    Valida el formato y dígito verificador de un RUT chileno.
    """
    rut = rut.replace(".", "").replace("-", "").upper()
    if not rut[:-1].isdigit() or len(rut) < 8:
        raise ValidationError("El RUT debe tener al menos 8 dígitos y un dígito verificador.")
    cuerpo = rut[:-1]
    dv = rut[-1]
    suma = 0
    multiplo = 2
    for c in reversed(cuerpo):
        suma += int(c) * multiplo
        multiplo = 9 if multiplo == 7 else multiplo + 1
    resto = suma % 11
    dv_esperado = "K" if 11 - resto == 10 else "0" if 11 - resto == 11 else str(11 - resto)
    if dv != dv_esperado:
        raise ValidationError("El RUT chileno no es válido.")

class DespachoSchema(ma.Schema):
    numero_guia = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    rut_empresa = fields.Str(required=True, validate=validar_rut_chileno)

    class Meta:
        fields = ("numero_guia", "rut_empresa")

class DespachoSchema(ma.Schema):
    numero_guia = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    rut_empresa = fields.Str(required=True, validate=validar_rut_chileno)

    class Meta:
        fields = ("numero_guia", "rut_empresa")

class LoginSchema(ma.Schema):
    rut = fields.Str(required=True, validate=validate.Length(min=8, max=12))
    password = fields.Str(required=True, validate=validate.Length(min=4))
    class Meta:
        fields = ("rut", "password")

class RecepcionSchema(ma.Schema):
    numero_guia = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    rut_empresa = fields.Str(required=True)  # Puedes agregar validación si lo deseas

    class Meta:
        fields = ("numero_guia", "rut_empresa")