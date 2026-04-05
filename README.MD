# Parcial 2C · Infraestructura Multi-Hypervisor (KVM/Libvirt + VirtualBox)

Implementación de infraestructura reproducible para una aplicación de microservicios con:

- **Vagrant** para levantar el `control-node`
- **Terraform** para aprovisionar `vm-haproxy` y `vm-microservices`
- **Ansible** para configurar servicios
- **Docker Compose** para desplegar microservicios
- **HAProxy** como punto de entrada único con balanceo por ruta y round-robin

Este branch incluye la etapa de **balanceo de carga con HAProxy** con validaciones de:

- routing por prefijo (`/api/users`, `/api/products`, `/api/orders`)
- estado de backends en stats
- distribución round-robin
- failover sin interrupción del servicio

---

## Arquitectura

Cliente → `vm-haproxy:80` → backends en `vm-microservices`

- `/api/users/*` → `3001`, `3011`
- `/api/products/*` → `3002`, `3012`
- `/api/orders/*` → `3003`, `3013`

Además:

- stats de HAProxy en `:8080/stats` (Basic Auth)
- health checks activos (`GET /health`)

---

## Estructura del proyecto

- `vagrant/`
	- `kvm-libvirt/Vagrantfile`
	- `virtualbox/Vagrantfile`
	- `scripts/` (bootstrap y helper scripts)
- `terraform/`
	- `kvm-libvirt/`
	- `virtualbox/`
- `ansible/`
	- `playbooks/`
	- `inventory/`
	- `roles/`
- `ssh-keys/`

---

## Requisitos

### Entorno Linux (openSUSE + KVM/Libvirt)

- Vagrant
- plugin `vagrant-libvirt`
- KVM/libvirt activos en host

### Entorno Windows (VirtualBox)

- Vagrant
- VirtualBox

---

## Flujo de despliegue

### 1) Levantar control-node

#### KVM/Libvirt

Desde `vagrant/kvm-libvirt`:

- `vagrant up`

#### VirtualBox

Desde `vagrant/virtualbox`:

- `vagrant up`

### 2) Entrar al control-node

- `vagrant ssh`

### 3) Desplegar infraestructura completa

Dentro de `control-node`:

- `~/deploy-infrastructure.sh`

Esto ejecuta Terraform + Ansible y deja listos:

- `vm-haproxy`
- `vm-microservices`
- inventario generado en `/home/vagrant/ansible/inventory/hosts.yml`

---

## Scripts helper (control-node)

Generados por `create-helper-scripts.sh`:

- `~/deploy-infrastructure.sh`
- `~/destroy-infrastructure.sh`
- `~/check-status.sh`
- `~/test-endpoints.sh`
- `~/test-roundrobin.sh`
- `~/test-failover.sh`

---

## Validación de HAProxy (entregables)

### 1) Estado general + stats

- `~/check-status.sh`

Esperado:

- VMs `REACHABLE`
- puerto `80` de HAProxy activo
- stats en `8080` respondiendo
- auth de stats `OK`

### 2) Routing por prefijo

- `~/test-endpoints.sh`

Esperado:

- `/api/users/` → `HTTP 200`
- `/api/products/` → `HTTP 200`
- `/api/orders/` → `HTTP 200`

### 3) Round-robin

- `~/test-roundrobin.sh`

Esperado:

- cada servicio distribuye requests entre **al menos 2 instancias**

### 4) Failover

- `SERVICE=users INSTANCE_DOWN=users-service-1 ~/test-failover.sh`

Esperado:

- instancia detenida pasa a `DOWN` en stats
- requests siguen devolviendo `HTTP 200`
- al recuperar, vuelve a `UP`

---

## Endpoints de referencia

Los IPs exactos dependen del proveedor y salen al final de `deploy-infrastructure.sh`.

Ejemplo (libvirt):

- HAProxy HTTP: `http://192.168.123.20:80`
- HAProxy stats: `http://192.168.123.20:8080/stats`
- Users: `http://192.168.123.20/api/users/`
- Products: `http://192.168.123.20/api/products/`
- Orders: `http://192.168.123.20/api/orders/`

Acceso desde host físico (a través de control-node):

- KVM/libvirt host -> `http://192.168.123.10/api/users/`
- KVM/libvirt stats -> `http://192.168.123.10:8080/stats`
- VirtualBox host -> `http://192.168.57.10/api/users/`
- VirtualBox stats -> `http://192.168.57.10:8080/stats`

Acceso recomendado y estable desde host (idéntico en ambos proveedores):

- API vía port-forward: `http://127.0.0.1:18080/api/users/`
- Stats vía port-forward: `http://127.0.0.1:18081/stats`

---

## Notas operativas

- Las IPs de backend en HAProxy se toman del inventario para evitar hardcode entre libvirt y VirtualBox.
- En ambos proveedores, `control-node` ejecuta un proxy hacia `vm-haproxy` y Vagrant publica los puertos `18080` y `18081` en `127.0.0.1` del host.
