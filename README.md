# MYSQL-Install


MYSLQ Install - This role is to install mysql software. 

Files contain mysql 5.6.27 software, my.cnf confuguration file, mysql.server init startup script.

MYSQL-MEB - Install mysql enterprise backup. 

Files contain meb 3.12.1 software,  meb.pl - meb script to backup mysql --slave database to disk, purge.pl -- script to purge mysql enterprise backup files

MYSQL-DB -- 

Create new user using ansible-myslq module and secure the default MYSQL install, update root password & remove anonymos users from the database. 

Execute the command to install MYSQL -- ansible-playbook mysql-install.yml --vault-password-file ~/.vault_pass.txt
