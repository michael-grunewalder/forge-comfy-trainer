# Use the mandatory large PyTorch base image
FROM runpod/pytorch:1.0.2-cu1281-torch271-ubuntu2204

# Set a non-root working directory for security
WORKDIR /workspace/app

# Set environment variables (common for ML/RunPod environments)
ENV PYTHONUNBUFFERED=1

# Copy the startup script and your application code
# Assuming your main application logic is in a folder named 'src'
COPY start.sh .
COPY src/ /workspace/app/src/

# Install any additional system dependencies needed for your specific application.
# CRITICAL OPTIMIZATION: Combine RUN commands using '&&' and clean the apt cache 
# in the *same layer* to prevent temporary files from bloating the image history.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Example: add necessary tools like git or nano if your app needs them
    git \
    nano \
    # Cleanup step is mandatory in the same RUN block
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies (use --no-cache-dir to save space)
# Example: replace requirements.txt with your actual requirements file
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Mark port 3000 as exposed (common for web UIs like ComfyUI/webui, change if needed)
EXPOSE 3000

# Set the entrypoint to the startup script
# This script will handle model downloading, environment checks, and finally launch the app
ENTRYPOINT ["/bin/bash", "start.sh"]
