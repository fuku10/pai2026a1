lerobot-rollout \
  --strategy.type=base \
  --policy.path=fkmt/act_so101_picking \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM0 \
  --robot.id=my_awesome_follower_arm \
  --robot.cameras="{ top: {type: opencv, index_or_path: /dev/video2, width: 320, height: 240, fps: 30, fourcc: 'MJPG'}, wrist: {type: opencv, index_or_path: /dev/video0, width: 640, height: 480, fps: 30, fourcc: 'MJPG'}}" \
  --task="Pick a pooley" \
  --duration=60