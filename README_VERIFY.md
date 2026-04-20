# Verificación

## Comprobar integridad
sha512sum -c package/checksums.sha512

## Verificar firma
gpg --verify package/signature.asc package/manifest.json

## Resultado
- Si todo está correcto → OK
- Si algo cambia → FAIL
