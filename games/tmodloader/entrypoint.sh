cd /home/container
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP=`ip route get 1 | awk '{print $(NF-2);exit}'`
apt update
apt install -y curl jq file unzip

if [ -z \"$GITHUB_USER\" ] && [ -z \"$GITHUB_OAUTH_TOKEN\" ] ; then
    echo -e \"using anon api call\"
else
    echo -e \"user and oauth token set\"
    alias curl='curl -u $GITHUB_USER:$GITHUB_OAUTH_TOKEN '
fi

## get release info and download links
LATEST_JSON=$(curl --silent \"https:\/\/api.github.com\/repos\/tmodloader\/tmodloader\/releases\" | jq -c '.[]' | head -1)
RELEASES=$(curl --silent \"https:\/\/api.github.com\/repos\/tmodloader\/tmodloader\/releases\" | jq '.[]')


if [ -z \"$VERSION\" ] || [ \"$VERSION\" == \"latest\" ]; then
    echo -e \"defaulting to latest release\"
    DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i tmodloader.zip)
else
    VERSION_CHECK=$(echo $RELEASES | jq -r --arg VERSION \"$VERSION\" '. | select(.tag_name==$VERSION) | .tag_name')
    if [ \"$VERSION\" == \"$VERSION_CHECK\" ]; then
        if [[ \"$VERSION\" == v0* ]]; then
            DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION \"$VERSION\" '. | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i linux | grep -i zip)
        else
            DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION \"$VERSION\" '. | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i tmodloader.zip)
        fi
    else
        echo -e \"defaulting to latest release\"
        DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i tmodloader.zip)
    fi
fi

## mkdir and cd to \/mnt\/server\/
mkdir -p \/mnt\/server

cd \/mnt\/server || exit 5

## download release
echo -e \"running: curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*\/}\"
curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*\/}

# Extracting tmod
FILETYPE=$(file -F ',' ${DOWNLOAD_LINK##*\/} | cut -d',' -f2 | cut -d' ' -f2)
if [ \"$FILETYPE\" == \"gzip\" ]; then
    tar xzvf ${DOWNLOAD_LINK##*\/}
elif [ \"$FILETYPE\" == \"Zip\" ]; then
    unzip -o ${DOWNLOAD_LINK##*\/}
else
    echo -e \"unknown filetype. Exiting\"
    exit 2
fi

echo "Attempting to patch tModLoader for Arm64!"
echo "Using modified dlls by https://github.com/NicolaeBet/tModLoader-ARM64-Fix/releases/tag/v2022.7.58.8"
echo "USE AT YOUR OWN RISK!"

# Get archetecture and version
arch=$(uname -m)

echo "Currently running ${arch} with tModLoader version "

if [[ $arch == aarch64 ]]]; then
    echo "Patching for arm64"
    # Patch tModLoader for arm64
    curl -L --silent "https://github.com/NicolaeBet/tModLoader-ARM64-Fix/releases/download/v2022.7.58.8/tModLoader_ARM64_Fix_v2022.7.58.8.zip" --output arm_patch.zip
    unzip arm_patch.zip -d .
    cp tModLoader_ARM64_Fix_v2022.7.58.8/tModLoader.dll tModLoader.dll
    cp tModLoader_ARM64_Fix_v2022.7.58.8/Libraries/steamworks.net/20.1.0/lib/netstandard2.1/Steamworks.NET.dll Libraries/steamworks.net/20.1.0/lib/netstandard2.1/Steamworks.NET.dll
    # Clean Up
    rm arm_patch.zip
    echo "Patching Successful!"
elif [[ $arch == aarch32 ]] && [[ $tmodversion = v2022.07.58.8 ]]; then
    echo "Unfortunately, there are no supported patches for ARM32..."
else
    echo "Unsupported architecture or version for patch"
fi

# ???
if [[ \"$VERSION\" == v0* ]]; then
    chmod +x tModLoaderServer.bin.x86_64
    chmod +x tModLoaderServer
else
    #tiny startup script for backward compatibility
    echo 'dotnet tModLoader.dll -server \"$@\"' > tModLoaderServer
    chmod +x tModLoaderServer
fi

# Clean files
echo -e \"Cleaning up extra files.\"
rm -rf terraria-server-*.zip rm ${DOWNLOAD_LINK##*\/}
if [[ \"$VERSION\" != v0* ]]; then
    rm -rf DedicatedServerUtils LaunchUtils PlatformVariantLibs tModPorter RecentGitHubCommits.txt *.bat *.sh
fi

## using config for difficulty as the startup parameter does not work -> config parser
mv \/mnt\/server\/serverconfig.txt \/mnt\/server\/config.txt
sed 's\/#difficulty\/difficulty\/' \/mnt\/server\/config.txt > \/mnt\/server\/serverconfig.txt
rm \/mnt\/server\/config.txt

## install end
echo \"-----------------------------------------\"
echo \"Installation completed...\"
echo \"-----------------------------------------\"",

# Setting User
# Using 7777 as user ID as that is tModLoader port 
# RUN set -eux; \
	groupadd -g 7777 ${USER}; \
	useradd -u 7777 -g 7777 -d ${HOME} -s /bin/sh ${USER};

# Set up folders
# RUN mkdir -p ${HOME}/.scripts 
# COPY ./scripts ${HOME}/.scripts
# RUN chmod -R +x ${HOME}/.scripts

# Relaxing crypto policies to get tModLoader to work
# RUN update-crypto-policies --set DEFAULT:SHA1
# TODO: this is kinda hacky. Remove once a better solution is found

# Set User
# RUN chown -R ${USER}:${USER} ${HOME}
# USER ${USER}:${USER}

### General Arguments
# ARG TMODLOADER_VERSION=latest \
    MODS_DIR=${HOME}/.local/share/Terraria/tModLoader/Mods \
    WORLDS_DIR=${HOME}/.local/share/Terraria/tModLoader/Worlds \
    MODCONFIGS_DIR=${HOME}/.local/share/Terraria/tModLoader/ModConfigs

### Initialize Container

# RUN mkdir -p ${MODS_DIR} ${WORLDS_DIR} ${MODCONFIGS_DIR}
# VOLUME ["${MODS_DIR}", "${WORLDS_DIR}", "${MODCONFIGS_DIR}"]

# Download and Install tModLoader 1.4
# WORKDIR ${HOME}

# RUN ${HOME}/.scripts/install-tmodloader.sh $TMODLOADER_VERSION

# Start Server
# CMD [ "sh", "-c", "${HOME}/.scripts/start-tmodloader.sh" ]