#!/usr/bin/env python3
"""
Generate UPF file for multi-parameter sweep simulations.
"""

# Configuration
yaml_file = "/projects/p32153/chistig-placematch/05-simulation-sweeps/05-model-simulation.yaml"
this_sweep_test = 'venues41instancesweep_9mar2026'
output_file = f"{this_sweep_test}_upf.txt"
num_instances = 41  #41
num_replicates = 120  #120

# Generate UPF file
with open(output_file, 'w') as f:
    line_number = 1
    
    for instance in range(1, num_instances + 1):
        for replicate in range(1, num_replicates + 1):
            # Format as standard command-line arguments (space-separated)
            params = f"--runno {line_number} --siminstance {instance} --replicate {replicate} --simparamsyamlfname {yaml_file}"
            f.write(f"{params}\n")
            line_number += 1

total_runs = num_instances * num_replicates
print(f"Generated {output_file} with {total_runs} parameter combinations")
print(f"  Instances: 1-{num_instances}")
print(f"  Replicates per instance: 1-{num_replicates}")
print(f"  YAML params file: {yaml_file}")