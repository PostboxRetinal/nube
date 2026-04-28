# API REST en AWS EC2 con Elysia

Este proyecto contiene la API REST que se ejecuta en la instancia EC2 de AWS.

## Archivos

- `package.json`: scripts y dependencia de Elysia para ejecutar la API con Bun.
- `index.ts`: servidor Elysia con endpoints GET y POST.
- `tsconfig.json`: configuracion TypeScript para Bun.

## Instalación en EC2

1. Navega al directorio del proyecto, por ejemplo `/home/ubuntu/api`.
2. Instala Bun si no está disponible: `curl -fsSL https://bun.com/install | bash`.
3. Ejecuta `bun install`.
4. Inicia la API con `bun run start` o `bun dev`.

## Desarrollo

- `bun dev`: inicia el servidor con recarga automatica.

## Probar localmente en EC2

- `curl http://localhost:3000/api/data`
- `curl -X POST http://localhost:3000/api/data -H "Content-Type: application/json" -d '{"test":"ok"}'`

## Probar desde Azure

Si Apache en Azure está configurado como proxy, accede a `http://<AZURE_PUBLIC_IP>/api/data`.
Si no, usa la IP pública de AWS directamente: `http://<AWS_PUBLIC_IP>:3000/api/data`.
