#!/bin/bash
tput setaf 4;
echo "";
echo "Misskey auto setup for Ubuntu";
echo "";

#region initial check
tput setaf 2;
echo "Check: Linux;"
if [ "$(command -v uname)" ]; then
	if [ "$(uname -s)" == "Linux" ]; then
		tput setaf 7;
		echo "	OK.";
		if ! [ -f "/etc/lsb-release" ]; then
			echo "	Warning: This script has been tested on Ubuntu and may not work on other distributions.";
		fi
	else
		tput setaf 1;
		echo "	NG.";
		exit 1;
	fi
else
	tput setaf 1;
	echo "	NG.";
	exit 1;
fi

tput setaf 2;
echo "Check: root user;";
if [ `whoami` != 'root' ]; then
	tput setaf 1;
	echo "	NG. This script must be run as root.";
	exit 1;
else
	tput setaf 7;
	echo "	OK. I am root user.";
fi
#endregion

#region user input
tput setaf 3;
echo "Misskey version setting";
tput setaf 7;

echo "Repository url where you want to install:"
read -p "> " -e -i "https://github.com/misskey-dev/misskey.git" repository;
echo "Branch or Tag"
read -p "> " -e -i "master" branch;

tput setaf 3;
echo "";
echo "Enter user name where you want to execute Misskey:";
tput setaf 7;
read -p "> " -e -i "misskey" misskey_user;

tput setaf 3;
echo "";
echo "Enter host where you want to install Misskey:";
tput setaf 7;
read -p "> " -e -i "example.com" host;
tput setaf 7;
hostarr=(${host//./ });
echo "OK, let's install $host!";

#region nginx
tput setaf 3;
echo "";
echo "Nginx setting";
tput setaf 7;
echo "Do you want to setup nginx?:";
read -p "[Y/n] > " yn
case "$yn" in
	[Nn]|[Nn][Oo])
		echo "Nginx and Let's encrypt certificate will not be installed.";
		echo "You should open ports manually.";
		nginx_local=false;
		cloudflare=false;

		echo "Misskey port: ";
		read\ -p "> " -e -i "3000" misskey_port;
		;;
	*)
		echo "Nginx will be installed on this computer.";
		echo "Port 80 and 443 will be open by modifying iptables.";
		nginx_local=true;

		misskey_port=3000;

		#region cloudflare

		tput setaf 3;
		echo "";
		echo "Cloudflare setting";
		tput setaf 7;
		echo "Do you use Cloudflare?:";

		read -p "[Y/n] > " yn2
		case "$yn2" in
			[Nn]|[Nn][Oo])
				echo "OK, you don't use Cloudflare.";
				echo "Let's encrypt certificate will be installed using the method without Cloudflare.";
				echo "";
				echo "Make sure that your Cloudflare DNS is set up.";
				cloudflare=false

				echo "Enter Email address to register certificate";
				read -p "> " cf_mail;
				;;

			*)
				cloudflare=true
				echo "OK, you want to use Cloudflare. Let's set up Cloudflare.";
				echo "Enter Email address you registered to Cloudflare:";
				read -p "> " cf_mail;
				echo "Open https://dash.cloudflare.com/profile/api-tokens to get Global API Key and enter here it.";
				echo "CloufFlare API Key: ";
				read -p "> " cf_key;

				mkdir -p /etc/cloudflare;
				cat > /etc/cloudflare/cloudflare.ini <<-_EOF
				dns_cloudflare_email = $cf_mail
				dns_cloudflare_api_key = $cf_key
				_EOF

				chmod 600 /etc/cloudflare/cloudflare.ini;
				#endregion
				;;
			esac
		;;
esac
#endregion

#region postgres
tput setaf 3;
echo "";
echo "Database (PostgreSQL) setting";
tput setaf 7;
echo "Do you want to install postgres locally?:";
read -p "[y/n] > " yn
case "$yn" in
	[Nn]|[Nn][Oo])
		echo "You should prepare postgres manually until database is created.";
		db_local=false;

		echo "Database host: ";
		read -p "> " -e -i "localhost" db_host;
		echo "Database port:";
		read -p "> " -e -i "5432" db_port;
		;;
	*)
		echo "PostgreSQL will be installed on this computer.";
		db_local=true;

		db_host=localhost;
		db_port=5432;
		;;
esac

echo "Database user name: ";
read -p "> " -e -i "misskey" db_user;
echo "Database user password: ";
read -p "> " db_pass;
echo "Database name:";
read -p "> " -e -i "mk1" db_name;
#endregion

#region redis
tput setaf 3;
echo "";
echo "Redis setting";
tput setaf 7;
echo "Do you want to install redis locally?:";
read -p "[Y/n] > " yn
case "$yn" in
	[Nn]|[Nn][Oo])
		echo "You should prepare Redis manually.";
		redis_local=false;

		echo "Redis host: ";
		read -p "> " -e -i "localhost" redis_host;
		echo "Redis port:";
		read -e -p "> " -e -i "6379" redis_port;
		;;
	*)
		echo "Redis will be installed on this computer.";
		redis_local=true;

		redis_host=localhost;
		redis_port=6379;
		;;
esac
#endregion

#region syslog
tput setaf 3;
echo "";
echo "Syslog setting";
tput setaf 7;
echo "Syslog host: ";
read -p "> " -e -i "localhost" syslog_host;
echo "Syslog port: ";
read -p "> " -e -i "514" syslog_port;
#endregion

tput setaf 7;
echo "";
echo "OK. It will automatically install what you need. This will take some time.";
echo "";
#endregion

set -eu;

tput setaf 3;
echo "Process: add misskey user ($misskey_user);";
tput setaf 7;
if cut -d: -f1 /etc/passwd | grep -q -x $misskey_user; then
	echo "$misskey_user exisits already. No user will be created.";
	else
		useradd -m -U -s /bin/bash $misskey_user;
fi

tput setaf 3;
echo "Process: apt install #1;";
tput setaf 7;
apt update -y;
apt install -y curl gnupg2 ca-certificates lsb-release git build-essential software-properties-common`$nginx_local && echo " certbot"``$cloudflare && echo " python3-certbot-dns-cloudflare"`;

if $nginx_local; then
	tput setaf 3;
	echo "Process: port open;"
	tput setaf 7;
	if ! cat /etc/iptables/rules.v4 | grep -q -x -e "-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT"; then iptables -I INPUT -p tcp --dport 80 -j ACCEPT; fi
	if ! cat /etc/iptables/rules.v4 | grep -q -x -e "-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT"; then iptables -I INPUT -p tcp --dport 443 -j ACCEPT; fi
	if ! cat /etc/iptables/rules.v6 | grep -q -x -e "-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT"; then ip6tables -I INPUT -p tcp --dport 80 -j ACCEPT; fi
	if ! cat /etc/iptables/rules.v6 | grep -q -x -e "-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT"; then ip6tables -I INPUT -p tcp --dport 443 -j ACCEPT; fi

	netfilter-persistent save;
	netfilter-persistent reload;

	tput setaf 3;
	echo "Process: prepare certificate;"
	tput setaf 7;
	if $cloudflare; then
		certbot certonly -t -n --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare/cloudflare.ini --dns-cloudflare-propagation-seconds 60 --server https://acme-v02.api.letsencrypt.org/directory `[ ${#hostarr[*]} -eq 2 ] && echo " -d $host -d *.$host" || echo " -d $host"` -m $cf_mail;
	else
		certbot certonly -t -n --agree-tos --standalone`[ ${#hostarr[*]} -eq 2 ] && echo " -d $host -d *.$host" || echo " -d $host"` -m $cf_mail;
	fi

	tput setaf 3;
	echo "Process: prepare nginx;"
	tput setaf 7;
	echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list;
	curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key;
	tput setaf 2;
	echo "Check: nginx gpg key;";
	tput setaf 7;
	if gpg --dry-run --quiet --import --import-options show-only /tmp/nginx_signing.key | grep -q 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; then
		echo "	OK.";
	else
		tput setaf 1;
		echo "	NG.";
		exit 1;
	fi
	sudo mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc;
fi

tput setaf 3;
echo "Process: prepare node.js;"
tput setaf 7;
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -;

if $redis_local; then
	tput setaf 3;
	echo "Process: prepare redis;"
	tput setaf 7;
	add-apt-repository ppa:chris-lea/redis-server -y;
fi

tput setaf 3;
echo "Process: apt install #2;"
tput setaf 7;
apt update -y;
apt install -y nodejs`$redis_local && echo " redis-server"``$nginx_local && echo " nginx"`;

echo "Display: Versions;"
echo "node";
node -v;
if $nginx_local; then
	echo "redis";
	redis-server --version;
fi
if $nginx_local; then
	echo "nginx";
	nginx -v;
fi

if $redis_local; then
	tput setaf 3;
	echo "Process: daemon activate: redis;"
	tput setaf 7;
	systemctl start redis-server;
	systemctl enable redis-server;
fi
if $nginx_local; then
	tput setaf 3;
	echo "Process: daemon activate: nginx;"
	tput setaf 7;
	systemctl start nginx;
	systemctl enable nginx;
	tput setaf 2;
	echo "Check: localhost returns nginx;";
	tput setaf 7;
	if curl http://localhost | grep -q nginx; then
		echo "	OK.";
	else
		tput setaf 1;
		echo "	NG.";
		exit 1;
	fi

fi

if $db_local; then
	tput setaf 3;
	echo "Process: install postgres;"
	tput setaf 7;
	wget https://salsa.debian.org/postgresql/postgresql-common/raw/master/pgdg/apt.postgresql.org.sh;
	sh apt.postgresql.org.sh -i -v 13;

	tput setaf 3;
	echo "Process: create user and database on postgres;"
	tput setaf 7;
	sudo -u postgres psql -c "CREATE ROLE $db_user LOGIN CREATEDB PASSWORD '$db_pass';" -c "CREATE DATABASE $db_name OWNER $db_user;"
fi

#region work with misskey user
su $misskey_user << MKEOF
set -eu;
cd ~;

tput setaf 3;
echo "Process: git clone;";
tput setaf 7;
git clone "$repository" -b "$branch" --depth 1;
cd misskey;

tput setaf 3;
echo "Process: create default.yml;"
tput setaf 7;
cat > .config/default.yml << _EOF
url: https://$host
port: $misskey_port

# PostgreSQL
db:
  host: '$db_host'
  port: $db_port
  db  : 'db_name'
  user: '$db_user'
  pass: '$db_pass'

# Redis
redis:
  host: localhost
  port: 6379

# ID type
id: 'aid'

# syslog
syslog:
  host: '$syslog_host'
  port: '$syslog_port'
_EOF

MKEOF
#endregion

tput setaf 3;
echo "Process: copy and apply nginx config;"
tput setaf 7;
sed -e 's/example.tld/$host/g' /home/misskey/misskey/docs/examples/misskey.nginx > /etc/nginx/conf.d/misskey.conf;
nginx -t;
systemctl restart nginx;

#region work with misskey user
su $misskey_user << MKEOF;
set -eu;
cd ~;
NODE_ENV=production;

cd misskey
tput setaf 3;
echo "Process: install npm packages;"
tput setaf 7;
npx yarn install

tput setaf 3;
echo "Process: build misskey;"
tput setaf 7;
npm run build

tput setaf 3;
echo "Process: initialize database;"
tput setaf 7;
npm run init

tput setaf 3;
echo "Check: If Misskey starts;"
tput setaf 7;
if timeout 20 npm start | grep -q "Now listening on port"; then
	echo "	OK.";
else
	tput setaf 1;
	echo "	NG.";
	exit 1;
fi
MKEOF
#endregion

tput setaf 3;
echo "Process: create misskey daemon;"
tput setaf 7;
cat > /etc/systemd/system/misskey.service << _EOF
[Unit]
Description=Misskey daemon

[Service]
Type=simple
User=misskey
ExecStart=/usr/local/bin/npm start
WorkingDirectory=/home/misskey/misskey
Environment="NODE_ENV=production"
TimeoutSec=60
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=misskey
Restart=always

[Install]
WantedBy=multi-user.target
_EOF

systemctl daemon-reload;
systemctl enable misskey;
systemctl start misskey;
systemctl status misskey;

echo "";
tput setaf 2;
tput bold;
echo "ALL MISSKEY INSTALLATION PROCESSES ARE COMPLETE!";
