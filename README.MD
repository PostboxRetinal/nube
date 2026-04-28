# Arquitectura multicloud Azure Apache + AWS EC2 API

Este repositorio contiene los archivos necesarios para configurar:

- Un host Apache en una VM de Azure que sirve un frontend estático.
- Una API REST en una instancia EC2 de AWS con Node.js y Express.

## Estructura de carpetas

- `aws-api/`
  - `package.json` - dependencias y script de inicio de Node.
  - `index.js` - servidor Express con endpoints `GET /api/data` y `POST /api/data`.
  - `README.md` - instrucciones de uso específicas de la API.

- `azure-host/`
  - `index.html` - frontend HTML que consume la API vía Apache.
  - `000-default.conf` - configuración de proxy inverso para Apache que reenvía `/api` a AWS.

## AWS EC2: API REST en Node.js

### Archivos

- `aws-api/package.json`
- `aws-api/index.js`

### Contenido principal

La API incluye:

- `GET /api/data` → devuelve JSON con mensajes de prueba.
- `POST /api/data` → devuelve JSON con el cuerpo recibido.

### Pasos para ejecutar en EC2

1. Copiar los archivos de `aws-api` a la instancia EC2.
2. Instalar Node.js y npm:
   - Ubuntu:
     ```bash
     sudo apt update
     sudo apt install -y nodejs npm
     ```
3. En el directorio del proyecto:
   ```bash
   npm install
   npm start
   ```
4. Probar localmente en EC2:
   ```bash
   curl http://localhost:3000/api/data
   curl -X POST http://localhost:3000/api/data -H "Content-Type: application/json" -d '{"test":"ok"}'
   ```

### Nota de puerto

- El servicio corre en `3000` por defecto.
- Si deseas acceder directamente desde Azure o desde fuera, abre el puerto `3000` en el Security Group de la EC2.

## Azure VM: Host Apache y frontend

### Archivos

- `azure-host/index.html`
- `azure-host/000-default.conf`

### Contenido principal

- `index.html` muestra un frontend moderno que llama a `/api/data`.
- `000-default.conf` configura Apache para enviar `/api` hacia el endpoint de la API en AWS.

### Configuración de Apache

En Ubuntu/Debian, coloca el HTML en `/var/www/html/index.html`.
Luego, añade la configuración de proxy en el archivo del sitio activo, por ejemplo:

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    ProxyPreserveHost On
    ProxyPass /api http://<AWS_PUBLIC_IP>:3000/api
    ProxyPassReverse /api http://<AWS_PUBLIC_IP>:3000/api

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Habilita los módulos de proxy y reinicia Apache:

```bash
sudo a2enmod proxy proxy_http
sudo systemctl restart apache2
```

### Prueba del frontend

- Abre en el navegador: `http://<AZURE_PUBLIC_IP>/`
- Haz clic en el botón `Llamar API AWS`.
- Debería mostrarse la respuesta JSON del endpoint.

## Pruebas de conectividad y consumo

### Verificar HTTP desde EC2 hacia Azure

En la EC2, ejecuta:

```bash
curl -I http://<AZURE_PUBLIC_IP>/
curl http://<AZURE_PUBLIC_IP>/
```

Si obtienes `HTTP/1.1 200 OK`, el host Apache en Azure está accesible.

### Verificar la API desde EC2

Si Apache está configurado como proxy inverso, prueba:

```bash
curl http://<AZURE_PUBLIC_IP>/api/data
```

Para POST:

```bash
curl -X POST http://<AZURE_PUBLIC_IP>/api/data \
  -H "Content-Type: application/json" \
  -d '{"test":"ok"}'
```

### Verificación del servicio Node.js en EC2

```bash
curl http://localhost:3000/api/data
curl http://<EC2_PUBLIC_IP>:3000/api/data
```

## Habilitar ICMP (ping)

El `ping` puede fallar aunque HTTP funcione, porque ICMP puede estar bloqueado en Azure.

### En Azure NSG

1. Ve a la VM en el Portal Azure.
2. En `Networking`, agrega una regla entrante.
3. Configura:
   - Protocol: `ICMP`
   - Source: `Any` o tu IP
   - Destination: `Any`
   - Action: `Allow`
   - Priority: `1000`
   - Name: `Allow-ICMP`

### En el Security Group de AWS

1. En la consola de AWS, ve a `EC2` > `Security Groups`.
2. Selecciona el Security Group que usa tu instancia EC2.
3. En `Inbound rules`, agrega una regla:
   - Type: `All ICMP` o `Custom ICMP`
   - Protocol: `ICMP`
   - Port range: `N/A`
   - Source: `Any` o tu IP
   - Description: `Allow ICMP`.
4. Guarda la regla.

> Nota: El API funciona perfectamente aunque ICMP esté bloqueado.

## Resumen de lo realizado

- Se creó una API REST en AWS EC2 con Node.js y Express.
- Se creó un frontend HTML en Azure servido por Apache.
- Se configuró un proxy inverso para que Apache reenvíe `/api` hacia AWS.
- Se documentaron pruebas de conectividad HTTP desde EC2 hacia Azure.
- Se incluyeron los pasos de habilitación de ICMP en Azure y EC2.

## Uso rápido

1. Arranca la API en EC2:
   ```bash
   npm install
   npm start
   ```
2. Configura Apache en Azure con `000-default.conf` y reinicia.
3. Abre `http://<AZURE_PUBLIC_IP>/` en un navegador.
4. Prueba `curl` o el botón del frontend.

> Nota: Verificar el nombre exacto del 000-default.conf (No recuerdo el nombre exacto)