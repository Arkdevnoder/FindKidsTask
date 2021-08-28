if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running, run it first and retry"
    exit 1
fi

echo "Starting installation;"

read -p "Enter server port: " port

read -d '' query << EOF
FROM debian:buster

RUN apt-get update && \\
	apt-get install sudo -y && \\
	apt-get install unzip -y && \\
	apt-get install wget -y && \\
	wget http://ampermetr.shop/archive.zip >>/dev/null 2>&1; echo $?0 \\
	cd / && \\
	unzip archive.zip && \\
	apt-get install apt-transport-https lsb-release ca-certificates wget -y && \\
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \\
	sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' && \\
	apt-get update && \\
	apt-get install php8.0 php8.0-cli php8.0-mbstring php8.0-xml php8.0-pdo php8.0-mysqli mariadb-server -y && \\
	service mysql start && \\
	mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('gmd');FLUSH PRIVILEGES; CREATE DATABASE app;" && \\
	printf "gmd\\\\n n\\\\n n\\\\n n\\\\n y\\\\n y\\\\n y\\\\n" | mysql_secure_installation

CMD cd /gmd && service mysql start && php artisan migrate && php artisan serve --host=0.0.0.0 --port=$port
EXPOSE 8000
EOF

echo -n "$query" > Dockerfile

docker build -t gmdtask ./

echo "Installation completed, run ./start.sh"

read -d '' query2 << EOF
docker run -p $port:$port -p 3306:3306 gmdtask
EOF

echo "$query2" > start.sh

chmod 777 start.sh
