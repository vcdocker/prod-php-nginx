#!/bin/bash
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_MYSQL_PASSWORD' 'example'
# (will allow for "$XYZ_MYSQL_PASSWORD_FILE" to fill in the value of
#  "$XYZ_MYSQL_PASSWORD" from a file, especially for Docker's secrets feature)

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ] || [ "$1" == supervisord ]; then
	if [ "$(id -u)" = '0' ]; then
		case "$1" in
		apache2*)
			user="${APACHE_RUN_USER:-www-data}"
			group="${APACHE_RUN_GROUP:-www-data}"

			# strip off any '#' symbol ('#1000' is valid syntax for Apache)
			pound='#'
			user="${user#$pound}"
			group="${group#$pound}"
			;;
		*) # php-fpm
			user='www-data'
			group='www-data'
			;;
		esac
	else
		user="$(id -u)"
		group="$(id -g)"
	fi

	# Wait for database service is ready
	# {
	# 	i=0
	# 	while [ $i -lt 10 ]; do
	# 		{
	# 			wp db check --allow-root
	# 			if [ $? -eq 0 ]; then
	# 				echo "Database connected"
	# 				break
	# 			else
	# 				echo "Wrong database credentials or database is not ready"
	# 				echo "retry in 5s ..."
	# 			fi
	# 		} || {
	# 			echo SKIP
	# 		}
	# 		((i++))
	# 		sleep 5
	# 	done

	# } || {
	# 	echo SKIP
	# }
fi

exec "$@"
