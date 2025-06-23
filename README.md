# **Whisper.cpp API with CUDA Acceleration**

This project provides a simple and efficient way to deploy whisper.cpp as a web API using Docker. It is optimized for production use with NVIDIA CUDA acceleration, leveraging a multi-stage Docker build to create a minimal and secure final container.

## **Features**

* **High Performance**: Utilizes NVIDIA CUDA for GPU-accelerated audio transcription.  
* **Optimized for Production**: Employs a multi-stage Dockerfile to produce a small, secure production image based on nvidia/cuda:cudnn-runtime.  
* **Easy Deployment**: Uses docker-compose to manage the service, making it simple to start, stop, and manage.  
* **HTTP API**: Exposes a straightforward /inference endpoint for easy integration into other applications.  
* **Flexible Configuration**: Easily configure models, ports, and other parameters through the docker-compose.yml file.

## **Prerequisites**

Before you begin, ensure you have the following installed on your host machine:

1. **NVIDIA GPU**: A CUDA-enabled NVIDIA graphics card.  
2. **NVIDIA Drivers**: The latest proprietary NVIDIA drivers for your GPU. You can verify the installation by running nvidia-smi.  
3. **Docker Engine**: [Installation Guide](https://docs.docker.com/engine/install/)  
4. **NVIDIA Container Toolkit**: This allows Docker containers to access the host's GPU. [Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

## **Quick Start**

Follow these steps to get the API server up and running.

### **1\. Initial Setup**

First, clone this repository or create the project directory structure. Then, run the provided setup script to create the necessary directories and download a default speech-to-text model.

```BASH
# This script creates the 'models' and 'samples' directories  
# and downloads the 'ggml-base.en.bin' model into the 'models' folder. 
bash setup.sh
```

### **2\. Build and Launch the Service**

Use docker-compose to build the Docker image and launch the container in the background.

The first build will take some time as it needs to download the base images and compile whisper.cpp from source.
```BASH
# Build the image (use \--no-cache for the first time or after changes)  
docker compose build --no-cache
```

```BASH
# Start the service in detached mode  
docker compose up -d
```

### **3\. Verify the Service**

You can check the container logs to ensure it started correctly and detected the GPU.
```BASH
docker compose logs -f
```

You should see output indicating that the CUDA device was found and the server is listening on port 8080\.

ggml\_cuda\_init: GGML\_CUDA=ON  
ggml\_cuda\_init: found 1 CUDA devices:  
ggml\_cuda\_init:   \- device 0: NVIDIA GeForce RTX 4090, compute capability 8.9  
...  
main: server listening on 0.0.0.0:8080

### **4\. Send a Transcription Request**

Place a sample audio file (e.g., myaudio.wav) inside the samples directory. You can then use curl or any other client to send a request to the /inference endpoint.

```BASH
#/inference
curl 127.0.0.1:8080/inference \
-H "Content-Type: multipart/form-data" \
-F file="@<file-path>" \
-F temperature="0.0" \
-F temperature_inc="0.2" \
-F response_format="json"
       
```

Use /load to load another model
```BASH
#/load
curl 127.0.0.1:8080/load \
-H "Content-Type: multipart/form-data" \
-F model="<path-to-model-file>"
```


The API will return a JSON object containing the transcribed text.
```JSON
{"text": " This is a test audio file.", ...}
```

## **Configuration**

### **Changing the Model**

To use a different model, download the desired .bin file from the [ggml Hugging Face repo](https://huggingface.co/ggerganov/whisper.cpp/tree/main) into your local ./models directory.

Then, update the command section in your docker-compose.yml file to point to the new model file:

```YAML
# docker-compose.yml  
services:  
  whisper-api:  
    # ...  
    command:  
      - "./server"  
      - "-m"  
      - "/models/ggml-medium.en.bin" # \<-- Change this line  
      # ...
```
After saving the change, restart the service to apply it: docker compose up \-d \--force-recreate.

### **Service Management**

* **Stop the service**: docker compose down  
* **Restart the service**: docker compose restart  
* **View logs**: docker compose logs \-f

## **How It Works**

This project uses a **multi-stage Docker build** for optimization:

1. **Build Stage**: A devel (development) image containing the full CUDA toolkit and compilers is used to clone and compile whisper.cpp from source.  
2. **Final Stage**: A lightweight cudnn-runtime image is used for the production container. The compiled server binary from the build stage is copied into this final image. This results in a much smaller and more secure container, as it does not contain any build tools or source code.
