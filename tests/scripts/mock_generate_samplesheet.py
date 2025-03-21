import os
import subprocess
import sys

def find_project_root(start_dir):
    """Find project root by walking up until we find main.nf or scripts dir."""
    current = os.path.abspath(start_dir)
    
    # Prevent infinite loop by setting a reasonable limit
    for _ in range(10):  # Maximum 10 levels up
        # Check if this looks like the project root
        if (os.path.exists(os.path.join(current, "main.nf")) and 
            os.path.isdir(os.path.join(current, "scripts"))):
            return current
        
        # Go up one directory
        parent = os.path.dirname(current)
        if parent == current:  # Reached filesystem root
            break
        current = parent
    
    return None

# Start from the current directory and search upward
project_dir = find_project_root(os.getcwd())

if not project_dir:
    # Try using a fixed path based on the error message
    project_dir = "/home/ec2-user/tools/read-sizer"
    if not os.path.exists(os.path.join(project_dir, "scripts/generate_samplesheet.py")):
        sys.stderr.write(f"Error: Could not find project directory\n")
        sys.exit(1)

# Path to the original script
original_script = os.path.join(project_dir, "scripts", "generate_samplesheet.py")

if not os.path.exists(original_script):
    sys.stderr.write(f"Error: Original script not found at {original_script}\n")
    sys.exit(1)

# Print paths for debugging
sys.stderr.write(f"Current directory: {os.getcwd()}\n")
sys.stderr.write(f"Found project directory: {project_dir}\n")
sys.stderr.write(f"Using original script: {original_script}\n")

# Add the --no-sign-request flag to the arguments
args = sys.argv[1:]
if '--no-sign-request' not in args:
    args.append('--no-sign-request')

# Execute the original script with the modified arguments
cmd = [sys.executable, original_script] + args
sys.stderr.write(f"Running command: {' '.join(cmd)}\n")
exit_code = subprocess.call(cmd)
sys.exit(exit_code)