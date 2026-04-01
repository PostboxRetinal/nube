#cloud-config

hostname: ${hostname}
fqdn: ${hostname}.infrastructure.local
manage_etc_hosts: true

users:
  - name: ${ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: [sudo, docker]
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}
    lock_passwd: false

chpasswd:
  list: |
    ${ssh_user}:vagrant
  expire: false

ssh_pwauth: true

package_update: true
package_upgrade: false

packages:
  - qemu-guest-agent
  - curl
  - wget
  - vim
  - net-tools
  - python3
  - python3-pip
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - echo "${hostname} provisioned by cloud-init" > /etc/motd

final_message: "Cloud-init completed for ${hostname} after $UPTIME seconds"