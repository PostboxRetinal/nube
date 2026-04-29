import { Elysia, t } from 'elysia';
import { cors } from '@elysiajs/cors';

const PORT = Number.parseInt(process.env.PORT ?? '3000', 10);

if (Number.isNaN(PORT)) {
  throw new Error('PORT debe ser un numero valido');
}

export const app = new Elysia()
  .use(cors(
    {
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type']
    }
  ))
  .onError(({ code, status }) => {
    if (code === 'NOT_FOUND') {
      return status(404, { message: 'No encontrado' });
    }

    if (code === 'PARSE') {
      return status(400, { message: 'El cuerpo de la solicitud debe ser JSON valido' });
    }
  })
  .get('/api/data', () => ({
    message: 'API REST en AWS EC2 funciona correctamente',
    timestamp: new Date().toISOString(),
    source: 'AWS EC2'
  }))
  .post('/api/data', ({ body }) => ({
    message: 'POST recibido en la API de AWS EC2',
    received: body,
    timestamp: new Date().toISOString()
  }))
  .put('/api/data/:id', ({ body, params: { id } }) => ({
    message: 'PUT recibido en la API de AWS EC2',
    id,
    updated: body,
    timestamp: new Date().toISOString()
  }), {
    params: t.Object({
      id: t.String({ minLength: 1 })
    })
  })
  .delete('/api/data/:id', ({ params: { id } }) => ({
    message: 'DELETE recibido en la API de AWS EC2',
    id,
    timestamp: new Date().toISOString()
  }), {
    params: t.Object({
      id: t.String({ minLength: 1 })
    })
  });

if (import.meta.main) {
  app.listen({
    port: PORT,
    hostname: '0.0.0.0'
  });

  console.log(`API escuchando en http://${app.server?.hostname}:${app.server?.port}`);
}
