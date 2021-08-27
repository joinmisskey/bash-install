#!/bin/bash
# Copyright 2021 aqz/tamaina, joinmisskey
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

tput setaf 2;
echo "Check: root user;";
if [ "$(whoami)" != 'root' ]; then
	tput setaf 1;
	echo "	NG. This script must be run as root.";
	exit 1;
else
	tput setaf 7;
	echo "	OK. I am root user.";
fi

tput setaf 3;
echo "Process: import environment and detect method;";
tput setaf 7;
if [ -f "/root/.misskey.env" ]; then
	. "/root/.misskey.env";
	if [ -f "/home/$misskey_user/.misskey.env" ]; then
		. "/home/$misskey_user/.misskey.env";
		method=systemd;
	elif [ -f "/home/$misskey_user/.misskey-docker.env" ]; then
		. "/home/$misskey_user/.misskey-docker.env";
	else
		misskey_user=misskey;
		misskey_directory=misskey;
		misskey_localhost=localhost;
		method=systemd;
		echo "use default"
	fi
else
	misskey_user=misskey;
	misskey_directory=misskey;
	misskey_localhost=localhost;
	method=systemd;
	echo "use default"
fi

echo "method: $method / user: $misskey_user / dir: $misskey_directory /  $misskey_localhost:$misskey_port"

if [ $method == "systemd" ]; then

#region work with misskey user
su $misskey_user << MKEOF
set -eu;
cd ~/$misskey_directory;
git pull;
MKEOF
#endregion

systemctl stop misskey

#region work with misskey user
su $misskey_user << MKEOF
set -eu;
cd ~/$misskey_directory;
npx yarn install;
npm run clean;
NODE_ENV=production npm run build;
npm run migrate;
MKEOF
#endregion

if [ $1 == "-r" ]; then
	apt update -y;
	apt full-upgrade -y;
	reboot;
else
	systemctl start misskey;
fi

elif [ $method == "docker" ]; then
echo "todo"
else
echo "todo"
fi
