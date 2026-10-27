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