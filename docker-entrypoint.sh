#!/bin/bash
set -euo pipefail

WAIT_FOR_DB="${WAIT_FOR_DB:-false}"

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
	if $WAIT_FOR_DB; then
		{
			i=0
			while [ $i -lt 20 ]; do
				{
					mysqladmin ping -h"$WAIT_FOR_DB" --silent
					if [ $? -eq 0 ]; then
						echo "Database connected"
						break
					else
						echo "Database is not ready"
						echo "retry in 5s ..."
					fi
				} || {
					echo SKIP
				}
				((i++))
				sleep 5
			done

		} || {
			echo SKIP
		}
	fi
fi

exec "$@"
