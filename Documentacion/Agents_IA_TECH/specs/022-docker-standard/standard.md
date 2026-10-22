================================================================================
ESPECIFICACION TECNICA - ESTANDAR DOCKER DEL KIT
================================================================================
Version:      1.0.0
Fecha:        2026-10-21
Estado:       NORMATIVA (obligatoria para toda app nueva o migrada)
Alcance:      empaquetado, configuracion, secretos y despliegue con Docker
              Compose o Podman Compose en servidores Linux del kit.
Referencia:   implementacion real de api_torniquetes (feature 002-docker-secrets)
              y arquitectura vigente de Boleteria Cardenales.

Convenciones de lenguaje normativo:
  DEBE       obligatorio, su incumplimiento bloquea el merge.
  NO DEBE    prohibido.
  DEBERIA    recomendado; si se omite, se justifica en el ADR de la app.
  PUEDE      opcional.

<app> = nombre de la aplicacion (minusculas, guion_bajo o guion, sin espacios).


================================================================================
1. PROPOSITO
================================================================================
Fijar una unica forma de construir y desplegar aplicaciones del kit, de modo
que cualquier agente o persona produzca la misma estructura, los mismos
nombres y el mismo flujo de secretos, sin decisiones ad-hoc por proyecto.

Regla de oro: si una app se despliega con Docker, cumple TODA esta
especificacion. No hay variantes "simplificadas" ni "temporales".


================================================================================
2. PRINCIPIOS NO NEGOCIABLES
================================================================================
P1. Los secretos son ARCHIVOS, no variables de entorno.
P1.1. Toda información sensible DEBE ir en secrets/, nunca en .env.
P1.2. Se consideran sensibles y deben ir en secrets/: IPs de servidores, nombres de bases de datos, usuarios de base de datos, passwords, tokens, api-key, jwt secret, tls key y cualquier credencial.
P2. El archivo .env contiene SOLO configuracion no sensible.
P2.1. .env solo puede contener: puertos, niveles de log, flags de feature, URLs públicas, nombres de servicio no sensibles. Nada que identifique, autentique o autorice.
P3. El arranque es fail-closed: si falta un secreto obligatorio, el proceso
    no arranca. Una dependencia caida (base de datos) NO tumba el proceso.
P4. La imagen NO contiene secretos. El repositorio NO contiene secretos.
P5. El contenedor corre como usuario no root con UID/GID 10001.
P6. docker-compose.yml es el artefacto de despliegue. NO se despliega con
    "docker run" suelto ni con "docker run --env-file" para credenciales.
P7. Reproducibilidad: version de imagen fija, dependencias con lockfile
    (go.sum, package-lock.json, poetry.lock, packages.lock.json).
P8. Una sola estructura para todas las apps: mismas carpetas, mismos
    nombres, mismo orden de resolucion de configuracion.


================================================================================
3. ESTRUCTURA OBLIGATORIA DE CARPETAS
================================================================================
<app>/
|-- Dockerfile
|-- docker-compose.yml
|-- .dockerignore
|-- .gitignore
|-- .env.example
|-- README.md
|-- secrets/
|   |-- README.md
|   `-- <app>/
|       |-- .gitkeep
|       |-- README.md
|       |-- db_password.txt          (si la app usa base de datos)
|       `-- api_key.txt              (si la app expone API autenticada)
|-- compose/                        (SOLO si hay 2 o mas servicios)
|   |-- app.yml
|   `-- <otro-servicio>.yml
|-- config/                         (opcional; solo archivos NO sensibles)
|-- data/                            (opcional; estado persistente, ignorado)
|-- logs/                            (opcional; solo si la app escribe archivos)
`-- src/ o el arbol del stack (cmd/, internal/, app/, etc.)

Reglas:
R3.1. Con UN solo servicio, docker-compose.yml vive en la raiz de la app.
R3.2. Con DOS o mas servicios (proxy, worker, cache), se parte en compose/.
      El archivo raiz puede quedar como include o eliminarse; se documenta.
R3.3. secrets/ NO se copia a la imagen y NO se versiona su contenido.
R3.4. data/ y logs/ NO se versionan. Si existen, se preservan entre
      despliegues (nunca "git reset --hard" sin backup).
R3.5. No se crean carpetas vacias sin proposito. Cada carpeta tiene README
      o un uso declarado en el README principal.


================================================================================
4. DOCKERFILE - REQUISITOS
================================================================================
4.1. Multi-stage obligatorio:
     - Etapa "build": imagen oficial del lenguaje, version mayor fija
       (ej: golang:1.25-alpine, node:22-alpine, python:3.12-slim).
     - Etapa "runtime": imagen minima (alpine, debian-slim o distroless).
4.2. Dependencias resueltas desde lockfile versionado en la etapa build.
4.3. Binario/artefacto compilado en build; runtime solo copia el resultado.
4.4. Paquetes minimos en runtime: ca-certificates y tzdata. Nada mas salvo
     justificacion documentada.
4.5. Usuario no root fijo:
       RUN addgroup -g 10001 app \
        && adduser -D -H -u 10001 -G app -h /app -s /sbin/nologin app
       USER 10001:10001
     En Debian/Ubuntu, equivalente con groupadd/useradd y los mismos IDs.
4.6. WORKDIR /app.
4.7. EXPOSE del puerto interno (por defecto 8080 para HTTP).
4.8. HEALTHCHECK contra /healthz (endpoint sin autenticacion):
       HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
         CMD wget -qO- "http://127.0.0.1:${PORT:-8080}/healthz" \
         | grep -q '"status":"ok"' || exit 1
     Si la imagen no tiene wget, se instala o se usa curl equivalente.
4.9. ENTRYPOINT/CMD en forma exec (JSON array). NO usar shell form.
4.10. PROHIBIDO:
      - ENV o ARG con secretos (quedan grabados en las capas).
      - COPY de .env o secrets/.
      - "USER root" o ausencia de USER.
      - Etiqueta "latest" en la imagen base.
      - apt/apk upgrade sin pin.
4.11. Imagen final etiquetada <app>:<semver> (ej: api-torniquetes:1.0.0).
4.12. Si el lenguaje necesita CGO o libc, se documenta y se elige la imagen
      base en consecuencia (no se fuerza alpine a ciegas).


================================================================================
5. SECRETOS - ESTRUCTURA Y REGLAS
================================================================================
5.1. Ubicacion: secrets/<app>/<nombre>.txt
5.2. Un archivo por secreto. Una linea. Sin espacios al inicio ni al final.
     El salto de linea final es aceptable (se recorta al leer).
5.3. Nombre del secret en Compose: <app>_<nombre>
     Ejemplo: api_torniquetes_db_password
5.4. Secretos estandar por tipo de app:
     | Archivo               | Secret Compose              | Variable    | Obligatorio |
     | db_password.txt       | <app>_db_password           | DB_PASSWORD | si usa DB   |
     | api_key.txt           | <app>_api_key               | API_KEY     | si hay API  |
     | jwt_secret.txt        | <app>_jwt_secret            | JWT_SECRET  | si firma JWT|
     | tls_key.txt           | <app>_tls_key               | TLS_KEY     | si termina TLS |
5.5. secrets/README.md DEBE documentar: estructura, reglas, creacion,
     permisos, rotacion, verificacion, exclusiones y problemas frecuentes.
5.6. secrets/<app>/README.md DEBE documentar: inventario de secretos,
     formato, flujo hasta el proceso, comandos de operacion y que NO va ahi.
5.7. .gitkeep obligatorio en secrets/<app>/ para conservar la carpeta.
5.8. PROHIBIDO: imprimir el contenido en consola, chat, issue, log o commit.
     Si se filtra: rotar antes de continuar.
5.9. Generacion recomendada: openssl rand -hex 32 (API keys y JWT),
     contrasena real de base provista por el DBA.
5.10. Rotacion: editar archivo -> docker compose up -d --force-recreate
      <servicio> -> verificar /healthz -> probar una operacion real.


================================================================================
6. DOCKER-COMPOSE.YML - PLANTILLA NORMATIVA
================================================================================
# <app> - despliegue con Docker Compose
# Puerto host <HOST_PORT> -> puerto interno 8080.
# El .env solo lleva configuracion no sensible; los secretos vienen de secrets/.

services:
  <app>:
    build:
      context: .
      dockerfile: Dockerfile
    image: <app>:1.0.0
    container_name: <app>
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - NET_RAW
    ports:
      - "<HOST_PORT>:8080"
    env_file:
      - .env
    environment:
      PORT: "8080"
      DB_PASSWORD_FILE: /run/secrets/<app>_db_password
      API_KEY_FILE: /run/secrets/<app>_api_key
    secrets:
      - <app>_db_password
      - <app>_api_key
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:8080/healthz | grep -q '\"status\":\"ok\"'"]
      interval: 30s
      timeout: 3s
      start_period: 10s
      retries: 3

secrets:
  <app>_db_password:
    file: ./secrets/<app>/db_password.txt
  <app>_api_key:
    file: ./secrets/<app>/api_key.txt

Reglas:
R6.1.  container_name = <app>, sin sufijos de entorno en v1.
R6.2.  restart: unless-stopped.
R6.3.  security_opt: no-new-privileges:true y cap_drop: NET_RAW obligatorios.
R6.4.  ports: "<HOST_PORT>:8080". Un puerto host por app, registrado en el
       catalogo de puertos (seccion 11). No se reutiliza entre apps.
R6.5.  env_file: .env para configuracion NO sensible. El archivo DEBE existir;
       se crea con "cp .env.example .env" en el primer despliegue.
R6.6.  environment: PORT fijo y las variables *_FILE de cada secreto.
R6.7.  secrets: lista de secrets consumidos; el bloque top-level "secrets:"
       mapea cada nombre a su archivo con "file:".
R6.8.  PROHIBIDO pasar secretos con env_file, environment con el valor,
       "docker run -e", ni "docker run --env-file" para credenciales.
       Motivo: docker inspect y /proc/<pid>/environ los muestran en texto
       plano a cualquiera con acceso al daemon.
R6.9.  PROHIBIDO mode: en los secrets: Compose sin Swarm lo ignora. Los
       permisos se fijan en el host (seccion 10).
R6.10. Si la app necesita persistencia, agregar volumen nombrado o bind
       explicito a data/ y documentarlo. Nunca montar la raiz del proyecto.
R6.11. RECOMENDADO limitar logs (evita llenar el disco):
         logging:
           driver: json-file
           options:
             max-size: "10m"
             max-file: "3"
R6.12. RECOMENDADO, si la app no escribe en disco:
         read_only: true
         tmpfs:
           - /tmp


================================================================================
7. RESOLUCION DE CONFIGURACION - 5 FUENTES
================================================================================
Toda variable DEBE resolverse en este orden exacto, tomando la primera fuente
que aporte un valor no vacio:

  1. variable de entorno NOMBRE            (sesion o contenedor)
  2. archivo indicado por NOMBRE_FILE      (mecanismo de Compose)
  3. /run/secrets/NOMBRE                   (Docker Secrets)
  4. archivo .env local                    (solo binario fuera de Docker)
  5. valor por defecto declarado en codigo (o ausencia -> error si es
     obligatoria)

Reglas:
R7.1. Un valor vacio o con solo espacios NO cuenta como definido: se pasa a
      la fuente siguiente.
R7.2. Los secretos conservan el valor tal cual. El unico recorte permitido es
      el salto de linea final del archivo (\r\n o \n).
R7.3. Las variables no sensibles se recortan en los bordes.
R7.4. Un archivo ilegible o vacio se comporta como ausente. NO se propaga la
      ruta ni el contenido en el mensaje de error.
R7.5. Los errores de configuracion nombran la VARIABLE, nunca el valor.
R7.6. El parser de .env soporta el subconjunto: NOMBRE=valor, lineas con #,
      comillas simples o dobles, prefijo "export", y "=" dentro del valor.
      Las lineas que no cumplen el formato se ignoran.
R7.7. La ruta del .env local se toma de CONFIG_ENV_PATH o, si no existe, de
      ".env" en el directorio de trabajo.
R7.8. El .env se cachea por ruta absoluta; no se relee por cada variable.
R7.9. En el contenedor la fuente 4 no existe: los secretos llegan por 2 o 3.

Pseudocodigo de referencia en lenguaje adaptado con 5 fuentes y trim.

Obligatorio: tests unitarios de las 5 fuentes, de la prioridad entre ellas,
de archivo vacio, de archivo inexistente, del parser .env y de que los
errores no filtran el contenido. Cobertura del modulo de configuracion >= 90 %.


================================================================================
8. .ENV Y .ENV.EXAMPLE
================================================================================
8.1. .env.example DEBE contener SOLO configuracion no sensible, comentada.
8.2. PROHIBIDO que .env.example contenga DB_PASSWORD, API_KEY, JWT_SECRET,
     certificados, tokens o cualquier credencial.
8.3. .env real NO se versiona.
8.4. Variables sensibles NO se documentan con valor; se documenta solo origen.
8.5. REGLA DE ORO DE SECRETOS: Toda información sensible DEBE ir en secrets/, nunca en .env.
      Datos sensibles obligatorios en secrets/: IPs de servidores, nombres de bases de datos, usuarios de base de datos, passwords, tokens, api-key, jwt secret, tls key y cualquier credencial de acceso.
      .env solo para configuración no sensible y pública.


================================================================================
9. .GITIGNORE Y .DOCKERIGNORE
================================================================================
Ver seccion 9 de la especificacion completa. .env nunca versionado, secrets/
solo README y .gitkeep.


================================================================================
10. PERMISOS EN SERVIDOR LINUX
================================================================================
10.1. Propietario 10001:10001, archivos modo 600, carpeta 700.
10.2. Verificacion con stat.


================================================================================
11. PUERTOS, NOMBRES E IMAGENES
================================================================================
Puerto interno 8080, container_name = <app>, image = <app>:<semver>.


================================================================================
12. SALUD, ARRANQUE Y TOLERANCIA A FALLOS
================================================================================
/healthz sin autenticacion, 200 ok / 503 degraded, fail closed por secreto.
restart unless-stopped.


================================================================================
13. LOGGING Y OBSERVABILIDAD
================================================================================
Logs a stdout/stderr JSON, sin secretos.


================================================================================
14. OPERACION
================================================================================
Primer despliegue, verificacion funcional, rotacion de secretos, prohibido git reset --hard sin backup.


================================================================================
15. CHECKLIST DE ACEPTACION
================================================================================
18 puntos verificables para Docker-ready.


================================================================================
16. ANTIPATRONES PROHIBIDOS
================================================================================
A1-A16 prohibidos.


================================================================================
17. PLANTILLAS COMPLETAS
================================================================================
Plantillas .gitignore, .dockerignore, secrets/README.md, ayudante configuracion, /healthz.


================================================================================
18. APLICACION EN EL KIT
================================================================================
Roles de pensador, arquitecto, devops, etc.


================================================================================
19. EJEMPLO DE REFERENCIA
================================================================================
api_torniquetes referencia.


================================================================================
20. ANEXO - COMANDOS DE VERIFICACION
================================================================================
docker compose config, up, ps, curl healthz, id, secretos legibles, permisos, git status, docker history, logs, rotacion.


================================================================================
FIN DE LA ESPECIFICACION
================================================================================
