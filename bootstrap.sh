#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='drupal'

# create project folder
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2.5 and php 5.5
sudo apt-get install -y apache2
sudo apt-get install -y php5

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php5-mysql

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}"
    <Directory "/var/www/html/${PROJECTFOLDER}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# set some environment variables for apache
sed -i 's/www-data/vagrant/g' /etc/apache2/envvars

# restart apache
sudo service apache2 restart

# install git
sudo apt-get -y install git

# install unzip
sudo apt-get install unzip

# put drupal 6 into the shared folder
wget -O temp.zip http://ftp.drupal.org/files/projects/drupal-6.36.zip; unzip temp.zip ; rm temp.zip; mv -v drupal-6.36/* "/var/www/html/${PROJECTFOLDER}/"
( cd "/var/www/html/${PROJECTFOLDER}" && mkdir "/var/www/html/${PROJECTFOLDER}/sites/default/files" )
( cp /vagrant/settings.php "/var/www/html/${PROJECTFOLDER}/sites/default/settings.php" )

# add drupal database
mysql -u root -p${PASSWORD} -e "CREATE DATABASE drupal"
mysql -u root -p${PASSWORD} < /vagrant/drupal.sql

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
