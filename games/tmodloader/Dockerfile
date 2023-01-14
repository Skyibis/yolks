### Set up docker base

# Using Rocky Linux
FROM rockylinux:9.0
ENV USER=container
ENV HOME=/home/container
# TODO: replace with alpine soon once the dotnet depencency issue is fixed

# Set up installs
RUN dnf update -y && dnf install -y epel-release && dnf install -y curl unzip findutils p7zip p7zip-plugins dotnet-runtime-6.0 crypto-policies-scripts \
	&& adduser -disabled-password --home /home/container container
# TODO: Look into why dotnet needs to be installed as well as the local version of dotnet installed by test

WORKDIR ${HOME}
COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]