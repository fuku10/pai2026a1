# 概要
SO-101でピッキングを行うためのデータ収集、学習、推論のコードです。
学習を含め、ローカルで行いました。

| ロボット | 俯瞰カメラ | 手首カメラ | OS | GPU | フレームワーク | モデル |
| --- | --- |  --- |  --- |  --- |  --- |  --- |
| SO-101 | ロジクールC920s | InnoMaker 1080P USB2.0 UVCカメラ | WSL2 + Ubuntu 24.04 | RTX 3070 | LeRobot 0.6.1 | ACT |

# スクリプト一覧

プロジェクトで使用する3つのシェルスクリプトの概要です。基本的にはLeRobotのチュートリアルのImitation Learning for Robotsをベースにしています。

https://huggingface.co/docs/lerobot/main/en/il_robots

| ファイル名 | 役割 | 実行方法 |
| :--- | :--- | :--- |
| `record.sh` | データ収集（10エピソード） | `./record.sh` |
| `record_resume.sh` | データの追加収集（追加10エピソード） | `./record_resume.sh` |
| `train.sh` | 学習 | `./train.sh` |
| `rollout.sh` | 推論 | `./rollout.sh` |

---

# 準備
基本的にLeRobotのGetting StartedのInstallationの通りに設定を行いました。（なお、mini-forgeを使い、LeRobotはpipでインストールしました。）

https://huggingface.co/docs/lerobot/main/en/installation

ただ、WSLを使っているため、カメラをWSL上のubuntuで認識するために以下の作業を実施しました。

https://learn.microsoft.com/ja-jp/windows/wsl/connect-usb


# 各スクリプトの詳細

## 1. record.sh
SO-101で10エピソード分のデータ収集をするスクリプトです。
カメラは俯瞰カメラと手首カメラを使います。WSL越しなので帯域制限が厳しく、俯瞰カメラは320x240,30fps,MJPGとし、手首カメラは640x480,30fps,MJPGとしました。（解像度が違うせいで、後で同じデータセットを使ってモデルをDiffusion Policyに変えて学習しようとすると、エラーが出ました。）
一度で大量のデータ収集をするのは大変なので、10エピソードで区切りました。

```sh
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM0 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{top: {type: opencv, index_or_path: /dev/video2, width: 320, height: 240, fps: 30, fourcc: 'MJPG'},\
                     wrist: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30, fourcc: 'MJPG'}}" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM1 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=fkmt/so101_picking \
    --dataset.num_episodes=10 \
    --dataset.single_task="Pick a pooley" \
    --dataset.streaming_encoding=true \
    --dataset.encoder_threads=2
```

## 2. record_resume.sh
追加で10エピソードのデータを収集します。
最終的に50エピソード分のデータを収集しました。

```sh
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM0 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{top: {type: opencv, index_or_path: /dev/video2, width: 320, height: 240, fps: 30, fourcc: 'MJPG'},\
                     wrist: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30, fourcc: 'MJPG'}}" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM1 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=fkmt/so101_picking \
    --dataset.num_episodes=10 \
    --dataset.single_task="Pick a pooley" \
    --dataset.streaming_encoding=true \
    --dataset.encoder_threads=2 \
    --dataset.root="$HOME/.cache/huggingface/lerobot/fkmt/so101_picking_20261027_143500" \
    --resume=true 
```

## 3. train.sh
ACTで10万ステップの学習をします。
バッチサイズは12としました。
RTX3070(VRAM8GB)では、Windowsのタスクマネージャー上で専用GPUメモリの消費量は約6GBでした。

```sh
lerobot-train \
  --dataset.repo_id=fkmt/so101_picking_20261027_143500 \
  --policy.type=act \
  --policy.push_to_hub=true \
  --output_dir=outputs/train/act_so101_picking \
  --job_name=act_so101_picking \
  --policy.device=cuda \
  --wandb.enable=false \
  --policy.repo_id=fkmt/act_so-101_picking \
  --batch_size=12 \
  --steps=100000 \
  --save_freq=10000
```

## 4. rollout.sh
推論します。ローカルのRTX3070で動かしました。（なお、上記LeRobotのチュートリアルImitation Learning for Robotsのコードだとrobot.idの設定が抜けていているのでキャリブレーションのやり直しを要求されます。）

```sh
lerobot-rollout \
  --strategy.type=base \
  --policy.path=fkmt/act_so101_picking \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.id=my_awesome_follower_arm \
  --robot.cameras="{ top: {type: opencv, index_or_path: /dev/video2, width: 320, height: 240, fps: 30, fourcc: 'MJPG'}, wrist: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30, fourcc: 'MJPG'}}" \
  --task="Pick a pooley" \
  --duration=60
```
