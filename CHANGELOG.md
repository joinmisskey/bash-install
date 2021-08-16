## v1.0.0
- MisskeyのDockerでの実行に対応。  
- 一部設定が反映されていないのを修正。
  * redisのホスト・ポートとかいろいろ
- /etc/fstabのswap設定が間違っていたのを修正（/swapfile→/swap）

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
