# VFCS

VFCS es un sistema para auditar decisiones de IA y detectar si han sido manipuladas.

## Qué hace
- Genera un registro verificable de eventos (GEN, EVAL, CLASS)
- Calcula hashes SHA-512
- Construye una cadena de integridad
- Firma el resultado con GPG

## Uso

./scripts/export_package.sh
./scripts/verify.sh

## Resultado

- OK → sistema íntegro
- FAIL → manipulación detectada
