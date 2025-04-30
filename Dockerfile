FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Install python, pip, zstd, git, and development tools
RUN dnf update -y && \
    dnf install -y git zstd python3 python3-pip gcc make libzstd-devel zlib-devel procps && \
    dnf clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    dnf install -y unzip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Clone and install sequence_tools
RUN git clone https://github.com/naobservatory/sequence_tools && \
    cd sequence_tools && \
    make install
