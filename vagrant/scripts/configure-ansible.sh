#!/bin/bash
# =============================================================================
# Configure Ansible
# =============================================================================

set -euo pipefail

echo "============================================"
echo "Configuring Ansible"
echo "============================================"

# Create Ansible directories
mkdir -p /home/vagrant/.ansible
mkdir -p /etc/ansible
mkdir -p /tmp/ansible_facts_cache

# Set ownership
chown -R vagrant:vagrant /home/vagrant/.ansible
chown -R vagrant:vagrant /tmp/ansible_facts_cache

# Create global Ansible configuration
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = /home/vagrant/ansible/inventory/hosts.yml
remote_user = vagrant
private_key_file = /home/vagrant/.ssh/infra_key
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 3600
stdout_callback = yaml
interpreter_python = auto_silent

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
pipelining = True
control_path = /tmp/ansible-%%r@%%h:%%p
EOF

echo "Ansible configuration created at /etc/ansible/ansible.cfg"

echo "============================================"
echo "Ansible Configuration Complete"
echo "============================================"