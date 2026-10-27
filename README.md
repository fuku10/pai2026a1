# 概要
SO-101でピッキングを行うためのデータ収集、学習、推論のコードです。

| OS | フレームワーク | モデル |
| --- | --- |  --- |
| WSL2 + Ubuntu 24.04 | LeRobot 0.6.1 | ACT |

# スクリプト一覧

プロジェクトで使用する3つのシェルスクリプトの概要です。

| ファイル名 | 役割 | 実行方法 |
| :--- | :--- | :--- |
| `record.sh` | データ収集（10エピソード） | `./record.sh` |
| `record_resume.sh` | データの追加収集（10エピソード） | `./record_resume.sh` |
| `train.sh` | 学習 | `./train.sh 2>&1 \| tee outputs/train/last_run.log` |

---

## 各スクリプトの詳細
wsl上のubuntu24.04で動作させました。

### 1. record.sh
SO-101でデータ収集をします。
カメラは俯瞰カメラと手首カメラを使います。WSL越しなので帯域制限が厳しく、俯瞰カメラは320x240,30fps,MJPGとし、手首カメラは640x480,30fps,MJPGとしました。
10エピソードだけ収集します。

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

### 2. record_resume.sh
追加で10エピソードのデータを収集します。
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
    --dataset.encoder_threads=2 \
    --dataset.root="$HOME/.cache/huggingface/lerobot/fkmt/so101_picking_20261027_143500" \
    --resume=true 
```

### 3. train.sh
ACTで10万ステップの学習をします。
バッチサイズは12です。
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
