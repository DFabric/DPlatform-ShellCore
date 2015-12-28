#!/bin/sh

. sysutils/nodejs.sh

# Install Meteor
# https://github.com/4commerce-technologies-AG/meteor
case $ARCH in
  arm*) cd $HOME
  git clone --depth 1 https://github.com/4commerce-technologies-AG/meteor.git
  # Check installed version, try to download a compatible pre-built dev_bundle and finish the installation
  meteor/meteor --version
  cd $DIR;;
  *) curl https://install.meteor.com/ | sh;;
esac
# Install Reaction
git clone https://github.com/reactioncommerce/reaction.git

# Start the latest release
cd reaction && git checkout master # default branch is development
./reaction

whiptail --msgbox "Reaction Commerce successfully installed!
To run Reaction:
cd reaction
./reaction

Open http://$IP:3000 in your browser" 12 48
