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

sudo systemctl stop misskey

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

sudo systemctl start misskey
