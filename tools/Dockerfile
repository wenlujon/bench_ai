FROM ubuntu:22.04

# Update packages and install necessary tools
RUN apt-get update && \
    apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/*

RUN apt update
RUN apt install -y vim git g++ python3 python3-pip wget python-is-python3 libhdf5-dev pkg-config libgl1

RUN pip install opencv-python pycocotools

# Create a new user named "test"
RUN useradd -m test && \
    echo "test:test" | chpasswd && \
    usermod -aG sudo test

RUN echo "test ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set the default user to "test"
USER test

# Set the working directory to the home directory of the user
WORKDIR /home/test

# Start a shell session as the "test" user
CMD ["/bin/bash"]

