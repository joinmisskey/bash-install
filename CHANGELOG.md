## v1.6.5
update.ubuntu.shで`docker image prune`するように

## v1.6.4
update.ubuntu.shでユーザーの切り替えに失敗するのを修正（sudo -uの代わりにsudo -iuを使うように）

## v1.6.3
arm64でdocker buildできない問題を修正

## v1.6.2
ユーザーの切り替えに失敗するのを修正（sudo -uの代わりにsudo -iuを使うように）

## v1.6.1
Redisのインストール方法を公式に従うようにしました。


https://redis.io/docs/getting-started/installation/install-redis-on-linux/  

```
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis
```

## v1.6.0
- Cloudflare非使用時のcertbotのエラーを修正しました。 https://github.com/joinmisskey/bash-install/pull/8
- PostgreSQLがインストールできない問題を修正しました（正しいインストール方法に変更しました）。また、PostgreSQLバージョンをv15にアップデートしました。 https://github.com/joinmisskey/bash-install/commit/61cb784619c95e540afa893d9d518a7e1e768c53  
    
## PostgreSQLのアップグレード方法 How to Upgrade Postgres

```
# Install posgtresql-common
sudo apt install postgresql-common;
sudo sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v 15;

# New cluster (15 main) is created during installation, but delete.
sudo pg_dropcluster 15 main --stop;

# Backup to gzip
sudo -u postgres pg_dumpall | gzip -c > mis.gz;

# Update! (from 13 main)
sudo pg_upgradecluster 13 main;

# optional: Drop old cluster
# sudo pg_dropcluster 13 main
```

## v1.5.0
Node.js v18をインストールするように変更しました。

~~Misskey 12.110.1以上では、Node.js v18が必要です。~~  
developブランチではv18が必要ですが、masterおよびリリースでは必要ありません。

アップデートの際は、アップデートスクリプトを実行する前に、以下のコマンドを実行してください。

```
sudo systemctl stop example.com # Stop the instance.

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

## v1.4.1
Nginx設定をTLSv1.3に対応するようにしました。

https://github.com/misskey-dev/misskey-hub/commit/d0800a8ac720774c81a46af2d12f9343dd75f4ba

## v1.4.0
RedisのPPAリポジトリを公式のものへ変更しました。

以前のバージョンのスクリプトでインストールした方は、次のコマンドを適宜実行してください。

```
sudo add-apt-repository --remove ppa:chris-lea/redis-server;
sudo add-apt-repository ppa:redislabs/redis;
```

## v1.3.0
特に変更はありませんが、Misskey v12.96.0ではアップデートスクリプトが動作しませんのでご注意ください。

## v1.2.2
- NODE_OPTIONS=--max_old_space_size=3072 を指定

## v1.2.1
- 必要なメモリ量を3GBに

## v1.2.0
- ufwを使用するオプションを追加

## v1.1.0
- iptables-persistentをインストールするように


## v1.0.0
- MisskeyのDockerでの実行に対応。  
- 一部設定が反映されていないのを修正。
  * redisのホスト・ポートとかいろいろ
- /etc/fstabのswap設定が間違っていたのを修正（/swapfile→/swap）
- アップデートスクリプトの拡充

## v0.2.0
FFmpegをインストールするように  
Make the script install FFmpeg.

### To install FFmpeg
FFmpegがないと、動画のサムネイルが表示されません。
以前のバージョンを実行された方は、以下のコマンドでFFmpegをインストールできます。

Thumbnail of videos will not be displayed without FFmpeg.
If you have installed Misskey with any older version, you can install FFmpeg with the following command.

```
sudo apt install ffmpeg -y
```

## v0.1.3
Developmentビルドになっていたのを修正  
Fix not to build Misskey as Development build

## v0.1.2
Readme: Clean upでapt full-updateするように

## v0.1.1
表記修正  
Notation correction

## v0.1.0
The first release
