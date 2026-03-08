# Práctica: Aprovisionamiento con Vagrant

**Entorno:** openSUSE + KVM/libvirt + Vagrant (compilado desde fuente, RVM 3.3.10)

---

## 1. Objetivos

- Comprender el funcionamiento de los aprovisionadores **Shell**, **Puppet** y **Chef** con Vagrant.
- Configurar y resolver problemas comunes de red y montaje NFS con libvirt.

---

## 2. Herramientas

- Vagrant + vagrant-libvirt
- KVM/libvirt
- Provisioners: Shell, Puppet, Chef Solo

---

## 3. Estructura del proyecto

```
.
├── Vagrantfile
├── script.sh
├── docker_provision.sh
├── script_jupyter.sh
└── puppet/
    ├── manifests/
    │   └── site.pp
    ├── modules/
    │   └── baseconfig/
    │       ├── files/
    │       │   └── index.html
    │       └── manifests/
    │           └── init.pp
    └── cookbooks/
        └── nginx/
            └── recipes/
                └── default.rb
```

---

## 4. Aprovisionamiento Shell

### script.sh
Configura DNS, instala vsftpd y habilita IP forwarding

### script_jupyter.sh
Instala y configura Jupyter Notebook como servicio systemd

---

## 5. Aprovisionamiento Puppet

### puppet/manifests/site.pp

### puppet/modules/baseconfig/manifests/init.pp

### puppet/modules/baseconfig/files/index.html

---

## 7. Aprovisionamiento Chef (nginx)

### puppet/cookbooks/nginx/recipes/default.rb

> nginx corre en puerto **8080** para evitar conflicto con Apache en puerto 80.

---

## 8. Comandos útiles

```bash
# Iniciar VM sin aprovisionar
vagrant up servidor --provider libvirt --no-provision

# Aprovisionar VM (ejecuta todos los provisioners)
vagrant provision servidor

# Aprovisionar solo con un provisioner específico
vagrant provision servidor --provision-with chef_solo
vagrant provision servidor --provision-with puppet
vagrant provision servidor --provision-with shell

# Sincronizar carpetas manualmente (rsync)
vagrant rsync servidor

# Sincronización rsync en caliente (auto-sincroniza al detectar cambios)
vagrant rsync-auto servidor
```
---

## 9. Notas sobre libvirt y NFS

Al usar `vagrant-libvirt` en openSUSE, el aprovisionador de Puppet y Chef intentan montar carpetas via **NFSv3/UDP** internamente, lo cual puede fallar si el host no tiene UDP registrado en rpcbind. La solución es forzar **rsync** para las carpetas de Puppet y Chef:

```ruby
puppet.synced_folder_type = "rsync"
chef.synced_folder_type   = "rsync"
```

Las carpetas `/vagrant` y `/shared` pueden seguir usando **NFSv4/TCP** sin problemas.

Para sincronización en caliente de manifiestos Puppet o recetas Chef durante desarrollo:

```bash
# Terminal 1
vagrant rsync-auto servidor

# Terminal 2 — re-aprovisionar
vagrant provision servidor --provision-with puppet
vagrant provision servidor --provision-with chef_solo
```