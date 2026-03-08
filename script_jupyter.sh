#!/bin/bash

IP="192.168.100.3"

echo "Actualizando paquetes..."
apt update -y

echo "Instalando Python y pip..."
apt install -y python3 python3-pip

echo "Instalando Jupyter..."
pip3 install jupyter

echo "Configurando Jupyter para acceso externo..."
mkdir -p /home/vagrant/.jupyter
cat <<EOF > /home/vagrant/.jupyter/jupyter_notebook_config.py
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.token = ''
c.NotebookApp.password = ''
EOF

echo "Iniciando Jupyter al arranque..."
cat <<EOF > /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
User=vagrant
ExecStart=/usr/local/bin/jupyter notebook --config=/home/vagrant/.jupyter/jupyter_notebook_config.py
WorkingDirectory=/home/vagrant
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable jupyter
systemctl start jupyter

echo "Jupyter disponible en http://$IP:8888"