1.	**Imagen propia + DockerHub**. Construya una imagen propia de Docker en la cual despliegue un sitio web personalizado y súbalo a su repositorio de docker hub.

2.	**Volúmenes docker**. Investigue cómo funcionan los volúmenes en Docker para compartir directorios entre el anfitrión y un contenedor.

3.	**Docker + Flask**. En el siguiente repositorio encontrara los archivos requeridos para crear un container con una aplicación web Flask en Docker
- Clone el repositorio y pruebelo creando y corriendo un container. Tenga en cuenta que Flask esta siendo ejecutado en modo de prueba y expone el puerto 5000.    

4.  **Docker + Consul.** 
- Siga el turorial disponible en https://developer.hashicorp.com/consul/tutorials/archive/docker-container-agents para:
- Configurar y correr un servidor consul en docker.
- Configurar y correr un cliente consul
- Registrar un servicio. En este caso debe registrar la aplicación del punto anterior (Docker+Flask). Para esto debe:


5. Modificar el código de la aplicación Docker+Flask para agregar una función health para realizar el chequeo periódico

6. Modificar el comando de registro para agregar la función de chequeo, por ejemplo:

`docker exec fox /bin/sh -c "echo '{\"service\": {\"name\": \"flask-example\", \"tags\": [\"python\"], \"port\": 5000, \"check\": {\"http\": \"http://192.168.50.3:5000/health\", \"interval\": \"10s\", \"timeout\": \"5s\"}}}' > /consul/config/counting.json"`

NOTA: Para este punto tenga en cuenta que debe usar un contenedor docker disponible en docker hub. Por ejemplo, al momento de eleborar esta guia la ultima disponible era la versón 1.15.4 (no existe una version latest).

7. Verifique en el dashboard de consul el registro adecuado de la aplicación y compruebe que funcione el check correctamente cuando la aplicación este arriba y detecte cuando la aplicación no está disponible:
