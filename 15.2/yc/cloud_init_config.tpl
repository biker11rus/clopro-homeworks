#cloud-config
users:
  - name: ${user}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${ssh_key}
write_files:
- content: |
    <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>title</title>
        </head>
        <body>
          Hello, world!<br>
          <img src="https://storage.yandexcloud.net/rkhozyainov-backet/picture.png" alt="rkhozyainov" />
        </body>
      </html>
  path: /var/www/html/index.html
  owner: root:root
  permissions: '0644'