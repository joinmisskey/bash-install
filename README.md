# Misskey install shell script v4.0.0-beta

Misskeyを簡単にインストールするためのシェルスクリプトができました！  
いくつかの質問に答えるだけで、UbuntuサーバーへMisskeyを簡単にインストールできます！  
~~アップデート用のスクリプトも用意されています。~~ v4では準備中  

## ライセンス
[MIT License](./LICENSE)  

## 準備するもの
1. ドメイン  
2. Ubuntuがインストールされたサーバー  
3. Cloudflareアカウント（推奨）  

## 操作
### 1. SSH
サーバーにSSH接続します。  
（サーバーのデスクトップを開いている方はシェルを開きましょう。）  

### 2. 環境を最新にする
インストール前に、サーバーにインストールされている全てのパッケージを最新にし、再起動します。  
```
sudo apt update; sudo apt full-upgrade -y; sudo reboot
```

### 3. インストールをはじめる
> [!TIP]
> インストール前に[Tips](#Tips)を一読されることをお勧めします。  

再度サーバーにSSH接続し、管理者権限のある(sudoを実行できる)アカウントで以下のコマンドを実行してください。  

実行後、指示に従ってオプションを選択し、しばらく待つとインストールが完了します。  

```
wget https://raw.githubusercontent.com/joinmisskey/bash-install/v4/misskey-install.sh -O misskey-install.sh; sudo bash misskey-install.sh
```

### 4. アップデートする
> [!IMPORTANT]
> アップデートスクリプトは、環境のアップデートは行いません。CHANGELOG（日本語）および[GitHubのリリース一覧（英語）](https://github.com/joinmisskey/bash-install/releases)を参考に、適宜マイグレーション操作を行なってください。  

~~サーバーにSSH接続し、管理者権限のある(sudoを実行できる)アカウントで以下のコマンドを実行してください。~~  

```
※以下は準備中です。まだ動作しません。
wget https://raw.githubusercontent.com/joinmisskey/bash-install/v4/misskey-update.sh -O misskey-update.sh; sudo bash misskey-update.sh
```

## Issues & PRs Welcome
スクリプトが正常に動作しない場合、まずは以下をご確認ください。  
- AMD64(ARM64)で実行していること
  ※ARM64は検証環境が無いため、サポートが行えない場合があります。ご了承ください。
- スクリプトをUbuntu LTSで実行していること  
  Ubuntu以外のOSでは正しく動作しない可能性が高いです。またLTS以外のバージョンでは、Misskeyの実行に必要なパッケージがそのバージョンをサポートしていない可能性があります。  
- サーバー内で他のソフトウェア(別構成のMisskeyを含む)をインストール・実行していないこと  
  既にサーバー内で他のソフトウェアが実行されている場合、Misskeyが正常にインストールできない可能性があります。MisskeyをインストールするサーバーにはMisskeyのみをインストールすることをお勧めします。  
- 最新版のスクリプトをダウンロードしていること  
  最新版であるか不明な場合、一度スクリプトを削除して再度ダウンロードしてください。  

上記を確認してもスクリプトが動作しない場合、バグの可能性があります。  
インストールの際に指定されたオプションやインストールログを添付し、GitHubのIssue機能にてお知らせください。  

機能の提案についても歓迎いたします。  


# Tips
## Cloudflare Tunnelをインストールする場合
本スクリプトでは、Misskeyと同時にCloudflare Tunnelをインストール・セットアップすることが出来ます。  
Cloudflare Tunnelをインストールする場合、CloudflareのAPI Key, Account ID, Zone IDが必要です。オプション選択中に入力を求められますので、事前に以下の手順で準備を行ってください。  
1. Login to your cloudflare account
2. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
3. Create Token > Create Custom Token
4. It requires permission to `` Account/Cloudflare Tunnel - Edit `` and `` Zones/<yourzone>/DNS - Edit ``
5. Enter other values as appropriate (Tip: Because the API Key is used only during installation, we strongly recommend that you set the expiration as short as possible)
6. Continue to summary > Create Token, and Copy your API Key
7. Go to [Dashboard Home](https://dash.cloudflare.com/)
8. Go to your website(zone) page
9. In the API section, copy the Zone ID and Account ID (Tip: The API section is located at the bottom right or bottom of the page)

These instructions are quoted from the following: [https://github.com/Srgr0/cloudflaretunnel_installer?tab=readme-ov-file#prepare
](https://github.com/Srgr0/cloudflaretunnel_installer?tab=readme-ov-file#prepare)  


> [!WARNING]
> 以下は内容更新中です。実際のスクリプトの動作と説明が異なる部分がありますので、スクリプト本体も合わせてご確認ください。  
~~~
## Systemd or Docker?
v1から、インストールメソッドにsystemdとDockerとを選べるようにしました。

Dockerと言っても、**MisskeyのみをDockerで実行**し、RedisやPostgresなどはホストで直接実行します。  
[docker-composeですべての機能を動かす方法については、mamemonongaさんが作成したこちらの記事がおすすめです。](https://gist.github.com/mamemomonga/5549bb69cad8e5618e5527593d4890e0)

Docker Hubイメージを使う設定であれば、Misskeyのビルドが不要になるため、**一番お勧めです**。  
ただし、マイグレーションは必要なので、アップデート時にMisskeyを使えない時間がゼロになるわけではありません。  
また、Misskeyのビルド環境を準備しない(git pullしない)ので、フォークを動かしたくなった時に設定が面倒になります。

ローカルでDockerをビルドする方式は、パフォーマンス面で非推奨です。

systemdは、Docker Hubにイメージを上げるまでもないものの、フォークを使いたい場合にお勧めです。

お勧めする順番は次の通りです。

1. Docker Hub
2. systemd
3. Dockerビルド

## nginxを使うかどうか
サーバー1台でMisskeyを構築する場合は、nginxの使用をお勧めします。

ロードバランサーを設置する場合にはnginxをインストールせず、[Misskeyのnginx設定](https://misskey-hub.net/docs/admin/nginx.html)を参考にロードバランサーを設定するのがよいと思います。

## Add more swaps!
スワップを設定している場合、メモリが合計で3GB以上でなければスクリプトが動作しないようになっています。

## 途中で失敗してまたスクリプトを実行する場合
万が一途中で失敗してもう一度スクリプトを動作させる場合、次のことに注意してください。

- RedisやPostgresのインストールが終わっている場合、「install locally」はNoにしてください。  
  host・port設定はそのままEnterを押します。
  ユーザー名やパスワードは、前回実行した際に指定したものを入力します。

## .envファイルについて
インストールスクリプトは、2つの.envファイルを作成します。  
アップデートの際に使用します。

### /root/.misskey.env
misskeyを実行するユーザーを覚えておくために必要です。

### /home/(misskeyユーザー)/.misskey.env
systemdの場合に生成されます。  
主にディレクトリを覚えておくのに使用します。

### /home/(misskeyユーザー)/.misskey-docker.env
Dockerの場合に生成されます。  
実行されているコンテナとイメージの番号を保存しています。  
コンテナの番号はアップデートの際に更新されます。古いイメージは削除されます。

## 自分で管理する
インストール後、構成を変更する際に役立つかもしれないメモです。

"example.com"を自分のドメインに置き換えて読んでください。

### Misskeyディレクトリ
Misskeyのソースは`/home/ユーザー/ディレクトリ`としてcloneされます。  
（ユーザー、ディレクトリの初期値はともにmisskeyです。）

Misskeyディレクトリへは、以下のように移動するとよいでしょう。

```
sudo -iu ユーザー
cd ディレクトリ
```

もとのユーザーに戻るにはexitを実行します。

```
exit
```

### systemd
systemdのプロセス名はexample.comです。  
たとえば再起動するには次のようにします。

```
sudo systemctl restart example.com
```

journalctlでログを確認できます。

```
journalctl -t example.com
```

設定ファイルは`/etc/systemd/system/example.com.service`として保存されています。

### Docker
DockerはMisskeyユーザーでrootless実行されています。

sudo でMisskeyユーザーに入るときは、`XDG_RUNTIME_DIR`と`DOCKER_HOST`を変更する必要があります。

```
sudo -iu ユーザー
export XDG_RUNTIME_DIR=/run/user/$UID
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# プロセス一覧を表示
docker ps

# ビルド (リポジトリ: local/misskey:latest)
docker build -t local/misskey:latest ./misskey

# docker run
docker run -d -p 3000:3000 --add-host=docker_host:10.0.0.1 -v /home/misskey/misskey/files:/misskey/files -v "/home/misskey/misskey/.config/default.yml":/misskey/.config/default.yml:ro --restart unless-stopped -t "local/misskey:latest"

# ログを表示
docker logs --tail 50 -f コンテナID
```

ワンライナーなら次のようにします。

```
sudo -u ユーザー XDG_RUNTIME_DIR=/run/user/$(id -u ユーザー) DOCKER_HOST=unix:///run/user/$(id -u ユーザー)/docker.sock docker ps
```

### nginx
nginxの設定は`/etc/nginx/conf.d/example.com.conf`として保存されています。

### Redis
requirepassとbindを`/etc/redis/misskey.conf`で設定しています。

## Q. アップデート後に502でアクセスできない
Dockerでは、起動後にマイグレーションをするため、すぐにアクセスできません。  
マイグレーションが終わっているかどうか確認してみてください。

systemdの場合では、pnpm installに失敗している可能性があります。  

Misskeyディレクトリで次の内容を実行し、もう一度アップデートを実行してみてください。

```
pnpm run clean-all
```

journalctlでログを確認すると、たいていre2が云々という記述が見当たります。

## Q. 同じサーバーにもう1つMisskeyを建てたい
スクリプトは同じサーバーに追加でMisskeyをインストールすることは想定していません。  
幾つかの設定が上書きされるか、途中でエラーになってしまうでしょう。
~~~
