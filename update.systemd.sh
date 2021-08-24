#!/bin/bash
misskey_user=misskey
misskey_directory=misskey

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

if [ $# == 1 ] && [ $1 == "-r" ]; then
	apt update -y;
	apt full-upgrade -y;
	reboot;
else
	systemctl start misskey;
fi

