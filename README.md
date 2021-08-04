# Misskey install shell script v0.1.2
Install Misskey with one shell script!  
Misskeyを簡単にインストールするためのシェルスクリプトができました！

You can install misskey on an Ubuntu server just by answering some questions.  
いくつかの質問に答えるだけで、UbuntuサーバーへMisskeyを簡単にインストールできます！

## Ingredients - 準備するもの
1. A Domain - ドメイン
2. An Ubuntu Server - Ubuntuがインストールされたサーバー
3. A Cloudflare Account (recommended) - Cloudflareアカウント（推奨）

## Procedures - 操作
### 1. SSH
Connect to the server via SSH.  
(If you have the desktop open, open the shell.)

サーバーにSSH接続します。  
（デスクトップを開いている方はシェルを開きます。）

### 2. Clean up - 環境を最新にする

Make sure all packages are up to date and reboot.  
すべてのパッケージを最新にし、再起動します。

```
sudo apt update; sudo apt full-upgrade -y; sudo reboot
```

### 3. Start the installation - インストールをはじめる

Reconnect SSH and let's start installing Misskey.  
SSHを接続しなおして、Misskeyのインストールを始めましょう。

```
wget https://raw.githubusercontent.com/joinmisskey/bash-install/main/ubuntu.sh -O ubuntu.sh; sudo bash ubuntu.sh
```

## Environments in which the operation was tested
動作を確認した環境

### Oracle Cloud Infrastructure

This script runs well on following compute shapes complemented by Oracle Cloud Infrastructure Always Free services.
このスクリプトは、Oracle Cloud InfrastructureのAlways Freeサービスで提供されている2種類のシェイプのいずれにおいても動作します。

- VM.Standard.E2.1.Micro (AMD)
- VM.Standard.A1.Flex (ARM) [1OCPU RAM6GB or greater]

## Issues & PRs Welcome
If it does not work in the above environment, it may be a bug. We would appreciate it if you could report it as an issue, with the specified requirements you entered to the script.  
上記の環境で動作しない場合、バグの可能性があります。インストールの際に指定された条件を記載の上、GitHubのIssue機能にてご報告いただければ幸いです。

It is difficult to provide assistance for environments other than the above, but we may be able to solve your problem if you provide us with details of your environment.  
上記以外の環境についてのサポートは難しいですが、状況を詳しくお教えいただければ解決できる可能性があります。

Suggestions for features are also welcome.  
機能の提案についても歓迎いたします。
