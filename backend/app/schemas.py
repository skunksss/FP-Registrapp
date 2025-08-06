from flask_marshmallow import Marshmallow
from marshmallow import fields, validate, ValidationError

ma = Marshmallow()

def validar_rut_chileno(rut):
    """
    Valida el formato y dígito verificador de un RUT chileno.
    Algoritmo estándar: múltiplos de 2 a 7 y vuelve a 2.
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
        multiplo = 2 if multiplo == 7 else multiplo + 1
    resto = suma % 11
    dv_esperado = "K" if 11 - resto == 10 else "0" if 11 - resto == 11 else str(11 - resto)
    if dv != dv_esperado:
        raise ValidationError("El RUT chileno no es válido.")

class DespachoSchema(ma.Schema):
    numero_guia = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    rut_empresa = fields.Str(required=True, validate=validar_rut_chileno)
    observacion = fields.Str(allow_none=True)
    latitud = fields.Float(allow_none=True)
    longitud = fields.Float(allow_none=True)

    class Meta:
        fields = ("numero_guia", "rut_empresa", "observacion", "latitud", "longitud")

class RecepcionSchema(ma.Schema):
    numero_guia = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    rut_empresa = fields.Str(required=True, validate=validar_rut_chileno)  # Validación agregada
    observacion = fields.Str(allow_none=True)  # NUEVO
    latitud = fields.Float(allow_none=True)     # NUEVO
    longitud = fields.Float(allow_none=True)    # NUEVO

    class Meta:
        fields = ("numero_guia", "rut_empresa", "observacion", "latitud", "longitud")

class LoginSchema(ma.Schema):
    rut = fields.Str(required=True, validate=validate.Length(min=8, max=12))
    password = fields.Str(required=True, validate=validate.Length(min=4))

    class Meta:
        fields = ("rut", "password")
