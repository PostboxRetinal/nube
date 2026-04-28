const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/api/data', (req, res) => {
  res.json({
    message: 'API REST en AWS EC2 funciona correctamente',
    timestamp: new Date().toISOString(),
    source: 'AWS EC2'
  });
});

app.post('/api/data', (req, res) => {
  res.json({
    message: 'POST recibido en la API de AWS EC2',
    received: req.body,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`API escuchando en http://0.0.0.0:${PORT}`);
});
