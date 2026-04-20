# VFCS-IA

Validated Flow for Critical Systems – Intelligent Architecture

Proyecto independiente de investigación enfocado en la validación criptográfica, trazabilidad y auditoría de decisiones en sistemas de IA.  
Independent research project focused on cryptographic validation, traceability, and auditability of AI system decisions.

Autor / Author: Antonio Tena Salguero (Spain)

---

## TL;DR

VFCS-IA es un framework que convierte decisiones de sistemas de IA en evidencia verificable mediante hashing SHA-512, encadenado de eventos (GEN → EVAL → CLASS) y firma digital.  
VFCS-IA is a framework that turns AI system decisions into verifiable evidence using SHA-512 hashing, chained events (GEN → EVAL → CLASS), and digital signatures.

---

## Qué es / What it is

VFCS-IA define un flujo estructurado para registrar, validar y verificar decisiones de IA.  
VFCS-IA defines a structured flow to record, validate, and verify AI decisions.

Convierte una salida de IA en un paquete auditable con integridad comprobable.  
It transforms an AI output into an auditable package with provable integrity.

---

## Problema / Problem

Los sistemas de IA actuales no garantizan:
- que una salida no haya sido modificada  
- trazabilidad completa entre entrada, proceso y resultado  
- capacidad de auditoría técnica o forense  

Modern AI systems do not guarantee:
- that an output has not been modified  
- full traceability between input, process, and result  
- technical or forensic auditability  

---

## Solución / Solution

VFCS-IA introduce:
- hashing SHA-512 de cada elemento  
- encadenado de eventos mediante hashes  
- manifest con integridad verificable  
- firma digital GPG  

VFCS-IA introduces:
- SHA-512 hashing per element  
- chained events via hashes  
- manifest-based integrity  
- GPG digital signature  

---

## Flujo del sistema / System flow

Input → GEN → EVAL → CLASS → Output

GEN: captura la entrada y genera su hash  
GEN: captures input and generates its hash  

EVAL: ejecuta el sistema y produce una salida  
EVAL: executes the system and produces output  

CLASS: valida el resultado y enlaza todas las fases  
CLASS: validates the result and links all stages  

---

## Cadena de eventos / Event chain

Cada evento genera:
- hash propio (event_sha512)  
- hash encadenado con el anterior (chain_sha512)  

Each event generates:
- its own hash (event_sha512)  
- a chained hash including the previous state (chain_sha512)  

Esto crea una secuencia resistente a manipulaciones.  
This creates a tamper-evident sequence.

---

## Ejemplo / Example

Entrada: petición de resumen de contrato con cláusulas de terminación  
Input: request for contract summary with termination clauses  

GEN: se registra la entrada  
GEN: input is recorded  

EVAL: el sistema genera la respuesta  
EVAL: system generates output  

CLASS: se valida coherencia y ausencia de errores  
CLASS: coherence and correctness are validated  

---

## Uso / Usage

Ejecutar:

./scripts/export_package.sh  
./scripts/verify.sh  
./test_roundtrip.sh  

Resultado esperado:

VFCS EXPORT: OK  
VFCS VERIFY: OK  
VFCS ROUNDTRIP: OK  

OK → integridad verificada  
FAIL → manipulación detectada  

---

## Estructura del repositorio / Repository structure

```text
vfcs-ia/
├── scripts/
├── package/
│   ├── manifest.json
│   ├── checksums.sha512
│   ├── signature.asc
│   └── events/
├── viewer/
├── docs/
├── README.md
```

---

## Casos de uso / Use cases

- auditoría de decisiones de IA / AI audit trails  
- validación forense / forensic validation  
- cumplimiento normativo / compliance workflows  
- pipelines seguros / secure pipelines  

---

## Limitaciones / Limitations

- prototipo (MVP)  
- no valida integridad del entorno completo  
- requiere gestión de claves  

---

## Autor / Author

Antonio Tena Salguero  
Independent developer (Spain)

---

## Licencia / License

MIT
