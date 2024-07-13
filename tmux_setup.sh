#!/bin/bash

# Configuration variables
session_name="muse2024"
directory_name="MuSe2024-experimental"
conda_env_name="muse2024"

# Set pane border style
tmux new-session -d -s $session_name
tmux set-option -g pane-border-format "#{pane_index} #T"
tmux set-option -g pane-border-status top
tmux set-option -g pane-border-style fg=white,bg=default

# Get the number of available GPUs
num_gpus=$(nvidia-smi --query-gpu=index --format=csv,noheader | wc -l)

# Split the window vertically (creates left and right panes)
tmux split-window -h -p $((100 * (num_gpus - 1) / num_gpus))

# Select the left pane (index 0) and split it horizontally based on the number of GPUs
tmux select-pane -t 0
for i in $(seq 1 $((num_gpus - 1))); do
    tmux split-window -v -p $((100 * (num_gpus - i) / (num_gpus - i + 1)))
done

# Send commands to each left pane
for i in $(seq 0 $((num_gpus - 1))); do
    tmux select-pane -t $i
    tmux send-keys "cd $directory_name/" C-m
    tmux send-keys "conda activate $conda_env_name" C-m
    tmux send-keys "export CUDA_VISIBLE_DEVICES=$i" C-m
    tmux send-keys "clear" C-m
    tmux select-pane -t $i -T "GPU:$i"
done

# Select the right pane and run watch nvidia-smi with specific options
tmux select-pane -t $num_gpus
#tmux send-keys "watch -n 1 nvidia-smi" C-m
tmux send-keys 'watch -n 1 '\''nvidia-smi && nvidia-smi | tr -s " " | grep -Eo "| [0123456789]+ N/A N/A [0-9]{3,} .*" | while read -r line; do pid=$(echo $line | awk "{print \$4}"); cmdline=$(tr "\\0" " " < /proc/$pid/cmdline); user=$(ps -o uname= -p $pid); echo $line | awk -v cmdline="$cmdline" -v user="$user" "{print \$1\"\\t\"\$4\"\\t\"user\"\\t\"\$7\"\\t\"cmdline}"; done'\'' ' C-m

tmux select-pane -t $num_gpus -T "GPU Monitoring"

# Perform git pull in pane 0 after everything is done
tmux select-pane -t 0
tmux send-keys "git pull" C-m

# Select the first pane (pane 0) and leave the cursor there
tmux select-pane -t 0

# Attach to the session
tmux attach-session -t $session_name
