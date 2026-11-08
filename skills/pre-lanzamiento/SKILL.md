---
name: pre-lanzamiento
description: Auditoría de 25 puntos de seguridad y preparación para producción antes de meter usuarios reales en una app (datos, secretos, auth, inputs, abuso, pagos, IA, cabeceras, errores, respaldos). Usar cuando el usuario diga "pre-lanzamiento", "auditoría antes de lanzar", "25 puntos", o vaya a publicar/lanzar una app. Fuente: D:\Programas de Proyecto Claude\cada proyecto tiene que hacer esto\prompt-pre-lanzamiento.md.pdf (lista de @itsmarbuilds).
---

# Auditoría de 25 puntos antes de lanzar

Actúa como revisor de seguridad y de preparación para producción del proyecto. Lo peligroso de una app hecha con IA no es que no funcione: es que funcione y nadie sepa qué quedó abierto.

**Primero, entiende el stack.** Lee el repositorio (estructura, package.json/requirements, variables de entorno de ejemplo, esquema de base de datos, rutas/endpoints, middleware de auth, integraciones de pagos, llamadas a modelos de IA, CI/CD y despliegue). Resume en 5 líneas qué hace la app, qué stack usa y por dónde entran y salen los datos.

**Luego revisa los 25 puntos, uno por uno.** Para cada uno: ✅ Cumple / ⚠️ Parcial / ❌ Falta / ➖ No aplica (y cuál sería el equivalente), evidencia concreta (archivo:línea o comando) y, si falta, la corrección exacta.

## A. Acceso a datos
1. RLS (o equivalente) activo en todas las tablas; ninguna accesible sin política.
2. Cada fila tiene dueño (columna de propietario/tenant usada por las políticas).
3. Campos que el cliente no escribe: role, is_admin, price, balance, owner_id… no se aceptan desde el frontend.
4. Solo los campos necesarios: sin `select *` hacia el cliente.

## B. Claves y secretos
5. La pública sí, la secreta jamás: ninguna service_role/secret_key/token de servidor en el bundle ni en el repo.
6. Lo que va en la app es público.
7. Rotar antes de publicar cualquier clave que haya tocado un chat de IA, un log, un commit o un .env compartido.
8. Cada endpoint pide credencial; ninguna ruta/función abierta por olvido.
9. Token fuera de localStorage: cookies HttpOnly/Secure/SameSite o equivalente.

## C. Autenticación
10. Contraseñas con bcrypt/argon2 o proveedor de identidad; nunca texto plano ni hash casero.
11. Segundo factor disponible, al menos para administradores.

## D. Inputs
12. Validar en el servidor (zod/pydantic o similar en cada entrada).
13. Consultas parametrizadas; cero concatenación en SQL/NoSQL.
14. Codificar a la salida; nada de dangerouslySetInnerHTML/v-html/innerHTML con datos de usuario.
15. URLs, redirects y webhooks de usuario validados (allowlist, sin open redirect, sin SSRF).
16. Subidas renombradas y limitadas: nombre generado, tipo y tamaño verificados, fuera del árbol público.

## E. Costos y abuso
17. Rate limit y cuotas en lo que cuesta: IA, correos/SMS, generación de archivos.
18. Anti-bot donde se crean cuentas: captcha, verificación de correo o rate limit en registro y recuperación.

## F. Pagos
19. Los pagos fallan cerrados: webhook con firma verificada, idempotencia, precio del servidor nunca del cliente.

## G. Acciones de la IA
20. La IA no borra sin permiso: acciones destructivas con confirmación humana o permisos explícitos; herramientas de alcance mínimo.

## H. Red y cabeceras
21. CORS cerrado: orígenes explícitos, sin `*` en producción.
22. CSP, X-Content-Type-Options, X-Frame-Options/frame-ancestors, Referrer-Policy, HSTS.

## I. Errores, alertas y recuperación
23. Errores que no cuentan nada: sin stack traces ni rutas internas; debug=false.
24. Logs y alertas de eventos sensibles (login fallido, cambio de contraseña, pago).
25. Backup automático probado con una restauración real; el borrado de cuenta elimina de verdad (archivos y copias incluidos).

## Cierre obligatorio
- Tabla resumen con los 25 puntos y su estado.
- Los 5 hallazgos más graves ordenados por riesgo (impacto × facilidad de explotación), cada uno con su corrección.
- Lista de lo que NO se pudo verificar desde el código (configuración del proveedor en la nube, etc.) y qué debe revisar una persona.
- Veredicto: LISTO PARA LANZAR / LANZAR CON CORRECCIONES MENORES / NO LANZAR TODAVÍA.

No es una auditoría completa ni universal: si un punto no aplica al stack, dilo y nombra el equivalente. **No corregir nada sin decir antes qué se va a cambiar.**
