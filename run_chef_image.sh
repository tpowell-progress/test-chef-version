#!/bin/bash

function create_chef_image {
    local ubuntu_version=${1:-22.04}
    local chef_version=$2
    local image_name="chef-ubuntu:${ubuntu_version}-${chef_version}"

    echo "Creating Docker image: ${image_name}"

    # Create a temporary Dockerfile
    cat > Dockerfile.chef <<EOF
FROM ubuntu:${ubuntu_version}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl wget gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Chef
RUN curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v ${chef_version}

# Verify chef version
RUN chef-client --version

# Set chef as the entrypoint
CMD ["/bin/bash"]
EOF

    # Build the Docker image
    docker build -t ${image_name} -f Dockerfile.chef .

    # Clean up the temporary Dockerfile
    rm Dockerfile.chef

    echo "Successfully created ${image_name}"
}

# Default Ubuntu version
DEFAULT_UBUNTU_VERSION="22.04"
DEFAULT_CHEF_VERSION="18.8.54"

# Check if an Ubuntu version was specified
if [ $# -ge 1 ]; then
    ubuntu_version="$1"; shift
else
    ubuntu_version=$DEFAULT_UBUNTU_VERSION
fi

if [ $# -ge 1 ]; then
    chef_version="$1"; shift
else
    chef_version=$DEFAULT_CHEF_VERSION
fi

# Create Chef 18.8.54 image
create_chef_image "$ubuntu_version" "$chef_version"

if [ $# -ge 3 ]; then
  docker run -it "chef-ubuntu:${ubuntu_version}-${chef_version}" $*
else
  docker run -it "chef-ubuntu:${ubuntu_version}-${chef_version}" sh
fi
