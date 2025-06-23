# --- STAGE 1: Build Stage ---
# Use the development image which includes the full CUDA toolkit and compilers.
FROM nvidia/cuda:12.9.1-devel-ubuntu24.04 AS builder

# Set non-interactive mode for package installers.
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required for compiling the project.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential git wget cmake pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Clone the whisper.cpp repository.
WORKDIR /app
RUN git clone https://github.com/ggerganov/whisper.cpp.git

# Configure and build the project with CUDA support.
WORKDIR /app/whisper.cpp
RUN mkdir build && cd build && \
    cmake .. -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DGGML_CUDA=ON && \
    cmake --build . --config Release -j$(nproc)

# --- STAGE 2: Final Production Stage ---
# Use a lightweight runtime image for the final container.
# This image contains the necessary libraries to run CUDA/cuDNN applications.
FROM nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04

# Install runtime dependencies for whisper.cpp.
# libasound2t64 is required for audio handling on Ubuntu 24.04.
# libgomp1 is the GNU OpenMP library, often a runtime dependency.
RUN apt-get update && \
    apt-get install -y --no-install-recommends libasound2t64 libgomp1 && \
    rm -rf /var/lib/apt/lists/*

    # Set the working directory for the application.
WORKDIR /app

# Copy the compiled binaries from the builder stage.
COPY --from=builder /app/whisper.cpp/build/bin ./

# Expose the port the server will listen on.
EXPOSE 8080

# Define the default command to run when the container starts.
# This can be overridden in the docker-compose.yml file.
CMD ["./whisper-server", "-m", "/models/ggml-base.en.bin", "--host", "0.0.0.0", "--port", "8080"]
