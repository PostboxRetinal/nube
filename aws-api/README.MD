# API REST en AWS EC2

Este proyecto contiene la API REST que se ejecuta en la instancia EC2 de AWS.

## Archivos

- `package.json`: dependencias de Node.js.
- `index.js`: servidor Express con endpoints GET y POST.

## Instalación en EC2

1. Navega al directorio del proyecto, por ejemplo `/home/ubuntu/api`.
2. Ejecuta `npm install`.
3. Inicia la API con `npm start`.

## Probar localmente en EC2

- `curl http://localhost:3000/api/data`
- `curl -X POST http://localhost:3000/api/data -H "Content-Type: application/json" -d '{"test":"ok"}'`

## Probar desde Azure

Si Apache en Azure está configurado como proxy, accede a `http://<AZURE_PUBLIC_IP>/api/data`.
Si no, usa la IP pública de AWS directamente: `http://<AWS_PUBLIC_IP>:3000/api/data`.
