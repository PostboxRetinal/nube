# Cloud Computing Repository
## HAProxy - Load Balancing

En esta práctica implementaremos balanceo de carga con la ayuda de HAProxy. Enviaremos una petición al balanceador de carga HAProxy y obtendremos respuestas desde dos servidores web.

- Las peticiones no se realizan directamente a los servidores web, sino que el balanceador de carga decidirá que servidor será el encargado de procesar la petición.
- Los dos servidores tendrán solo apache corriendo y en el balanceador de cargase ejecutará HAProxy.
- La GUI del balanceador de carga será accesible desde la máquina anfitriona para visualizar el estado y estadísticas detalladas de los servidores web.
