#!/bin/bash

# Function to print a line
print_line() {
    printf '+%-19s+%-14s+%-11s+%-11s+%-15s+\n' "-----------------" "-------------" "----------" "----------" "--------------"
}

# Get a unique list of GPU nodes
nodes=$(sinfo -N -h -o "%N" | grep gpu | sort -u)

# Print header
echo "GPU Status Summary:"
print_line
printf "| %-18s | %-12s | %-9s | %-9s | %-13s |\n" "Node" "Total GPUs" "Used GPUs" "Available" "State"
print_line

count=0
for node in $nodes
do
    # Get node details
    node_info=$(scontrol show node $node)
    
    # Extract information
    total_gpus=$(echo "$node_info" | grep -oP 'Gres=gpu:\K\d+')
    alloc_gpus=$(echo "$node_info" | grep -oP 'AllocTRES=.*gres/gpu=\K\d+' || echo "0")
    avail_gpus=$((total_gpus - alloc_gpus))
    state=$(echo "$node_info" | grep -oP 'State=\K\w+')
    
    # Print the result
    printf "| %-18s | %-12s | %-9s | %-9s | %-13s |\n" "$node" "$total_gpus" "$alloc_gpus" "$avail_gpus" "$state"
    
    ((count++))
    
    # Print a line every 5 rows for better readability
    if [ $((count % 5)) -eq 0 ]; then
        print_line
    fi
done

# Print final line if not already printed
if [ $((count % 5)) -ne 0 ]; then
    print_line
fi

# Print total
total_nodes=$count
total_gpus=$(echo "$nodes" | xargs -I {} scontrol show node {} | grep -oP 'Gres=gpu:\K\d+' | awk '{sum+=$1} END {print sum}')
used_gpus=$(echo "$nodes" | xargs -I {} scontrol show node {} | grep -oP 'AllocTRES=.*gres/gpu=\K\d+' | awk '{sum+=$1} END {print sum}')
avail_gpus=$((total_gpus - used_gpus))

echo "Summary:"
echo "Total Nodes: $total_nodes"
echo "Total GPUs: $total_gpus"
echo "Used GPUs: $used_gpus"
echo "Available GPUs: $avail_gpus"
