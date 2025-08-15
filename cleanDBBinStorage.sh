docker exec owncloud-db sh -c "ls -alh /var/lib/mysql/mysql-bin.0*"
last=$(docker exec owncloud-db sh -c 'basename $(ls /var/lib/mysql/mysql-bin.0* | tail -n 1)')

echo -e "\nLast binary log file is: ${last}\n"
read -p "Everything up to ${last} will be removed, continue? [y/N]: "

if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo -e "Ok, cleaning up...\n"
	source /root/docker/docker-owncloud/.env
	docker exec owncloud-db sh -c "mysql -u root --password=${DB_ROOT_PASSWORD} -e \"PURGE BINARY LOGS TO '$last'\""
	echo -e "New binary log files: "
	docker exec owncloud-db sh -c "ls -alh /var/lib/mysql/mysql-bin.0*"
else
	echo "Ok aborting"
fi

