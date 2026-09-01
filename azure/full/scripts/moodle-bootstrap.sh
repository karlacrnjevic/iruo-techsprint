#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  apache2 \
  mariadb-server \
  php \
  php-cli \
  php-curl \
  php-gd \
  php-intl \
  php-mbstring \
  php-mysql \
  php-soap \
  php-xml \
  php-zip \
  unzip \
  curl \
  git \
  fuse3

# Install BlobFuse2 from Microsoft's Ubuntu repository
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
  -O /tmp/packages-microsoft-prod.deb

dpkg -i /tmp/packages-microsoft-prod.deb
apt-get update
apt-get install -y blobfuse2

rm -f /tmp/packages-microsoft-prod.deb

# Configure and mount Azure Blob Storage using Managed Identity
BLOB_MOUNT="/mnt/moodle-backups"
BLOB_CONFIG="/etc/blobfuse2-moodle.yaml"

mkdir -p "$BLOB_MOUNT"

cat > "$BLOB_CONFIG" <<EOF
allow-other: true

components:
  - libfuse
  - block_cache
  - attr_cache
  - azstorage

block_cache:
  block-size-mb: 16

azstorage:
  type: block
  account-name: ${storage_account_name}
  container: ${blob_container_name}
  endpoint: blob.core.windows.net
  mode: msi
EOF

chmod 600 "$BLOB_CONFIG"

blobfuse2 mount "$BLOB_MOUNT" \
  --config-file="$BLOB_CONFIG" \
  --streaming

systemctl enable apache2
systemctl enable mariadb

systemctl start apache2
systemctl start mariadb

# Prepare and mount the additional managed data disk
DATA_DISK="/dev/disk/azure/scsi1/lun0"
DATA_MOUNT="/mnt/moodledata"

mkdir -p "$DATA_MOUNT"

if [ -b "$DATA_DISK" ]; then
  if ! blkid "$DATA_DISK" >/dev/null 2>&1; then
    mkfs.ext4 "$DATA_DISK"
  fi

  if ! grep -q "$DATA_DISK" /etc/fstab; then
    echo "$DATA_DISK $DATA_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi

  mount -a
fi

mysql -e "CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'moodle'@'localhost' IDENTIFIED BY '${moodle_db_password}';"
mysql -e "GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

rm -f /var/www/html/index.html

if [ ! -d /var/www/html/moodle ]; then
  git clone --depth 1 -b MOODLE_405_STABLE https://github.com/moodle/moodle.git /var/www/html/moodle
fi

mkdir -p /mnt/moodledata/moodledata

if [ ! -L /var/moodledata ]; then
  rm -rf /var/moodledata
  ln -s /mnt/moodledata/moodledata /var/moodledata
fi

chown -R www-data:www-data /var/www/html/moodle
chown -R www-data:www-data /mnt/moodledata/moodledata

chmod -R 755 /var/www/html/moodle
chmod -R 770 /mnt/moodledata/moodledata

cat > /etc/apache2/sites-available/moodle.conf <<'APACHE'
<VirtualHost *:80>
    DocumentRoot /var/www/html/moodle

    <Directory /var/www/html/moodle>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $${APACHE_LOG_DIR}/moodle-error.log
    CustomLog $${APACHE_LOG_DIR}/moodle-access.log combined
</VirtualHost>
APACHE

a2dissite 000-default.conf
a2ensite moodle.conf
a2enmod rewrite

systemctl restart apache2

cat > /var/www/html/moodle-health.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
  <title>TechSprint Moodle</title>
</head>
<body>
  <h1>TechSprint Moodle node is running</h1>
</body>
</html>
HTML

chown www-data:www-data /var/www/html/moodle-health.html
