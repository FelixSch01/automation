# Check privileges
if (( $EUID == 0 ));
then
    echo "Please do not run this script as root."
    exit 0;
fi

# Pre-install setup
echo "1. Preparing to install packages";

## Proton
echo "1.1. Please download the 'Proton VPN RPM package' and install the repository.";
echo xdg-open https://protonvpn.com/support/official-linux-vpn-fedora/ &> /dev/null;
read -p "Press enter when this step is completed...";

echo "1.2. Please download the 'Proton Mail Bridge' RPM package to '$(pwd)'.";
echo xdg-open https://proton.me/mail/bridge &> /dev/null;
read -p "Press enter when this step is completed...";
wget https://proton.me/download/bridge_pubkey.gpg &> /dev/null;
sudo rpm --import bridge_pubkey.gpg &> /dev/null;
rpm --checksig protonmail-bridge-*.rpm &> /dev/null;
if (($? == 0));
then
    echo "Package signature has been verified.";
    install_proton_bridge=true;
else
    echo "Package signature could not be verified.";
    install_proton_bridge=false;
fi
rm bridge_pubkey.gpg &> /dev/null;

## Enable Flathub packages for Flatpak
echo "1.3. Enabling Flathub remote for Flatpak...";
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &> /dev/null;
sudo flatpak remote-modify --enable flathub &> /dev/null;

## Enable RPM Fusion/nonfree repository
# Note: not necessary
# echo "2.4. Enabling RPM Fusion/nonfree repository for DNF...";
# sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y &> /dev/null;
# dnf_rpm_fusion="discord";
dnf_rpm_fusion="";

# Install packages
    # Other
    #   Teams (deprecated, use PWA: https://techcommunity.microsoft.com/t5/microsoft-teams-blog/microsoft-teams-progressive-web-app-now-available-on-linux/ba-p/3669846?culture=en-us&country=us)
    #   Notion (no Linux app, use in browser)
    
echo "2. Installing packages";
echo "2.1. Upgrading packages (this can take a while)...";
echo "2.1.1. Upgrading DNF packages...";
sudo dnf upgrade -y &> /dev/null;
echo "2.1.2. Upgrading Flatpak packages...";
sudo flatpak update -y &> /dev/null;
echo "2.2. Installing packages (this can take a while)...";

# DNF packages
echo "2.2.1. Installing DNF packages..."
dnf_school="java-17-openjdk-devel";
dnf_proton="protonvpn python3-pip libappindicator-gtk3 gnome-tweaks gnome-shell-extension-appindicator gnome-extensions-app"
dnf_firefox="mozilla-https-everywhere mozilla-noscript mozilla-ublock-origin";
dnf_misc="thunderbird lyx anki keepassxc xournalpp neofetch lolcat";

dnf_packages="$dnf_rpm_fusion $dnf_school $dnf_proton $dnf_firefox $dnf_misc";
sudo dnf install $dnf_packages -y &> /dev/null;

# Flatpak packages
echo "2.2.2. Installing Flatpak packages..."
fp_school="org.geogebra.GeoGebra";
# Webcord is a Discord client that supports screen sharing on Wayland
fp_misc="com.jgraph.drawio.desktop com.spotify.Client io.github.spacingbat3.webcord";

fp_packages="$fp_school $fp_misc";
sudo flatpak install flathub $fp_packages -y &> /dev/null;

## Proton
echo "2.2.3. Installing PIP3 packages..."
pip3 install --user 'dnspython>=1.16.0' &> /dev/null;

echo "2.2.4. Installing Proton Mail Bridge..."
if (($install_proton_bridge == true));
then
    sudo dnf install protonmail-bridge-*.rpm -y &> /dev/null;
else
    echo "  Skipped Proton Mail Bridge since signature did not match.";
fi

## Jetbrains Toolbox
echo "2.2.5. Installing Jetbrains Toolbox..."
# begin jetbrains toolbox install script
# source: https://github.com/nagygergo/jetbrains-toolbox-install
function getLatestUrl() {
USER_AGENT=('User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36')

URL=$(curl 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' -H 'Origin: https://www.jetbrains.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H "${USER_AGENT[@]}" -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://www.jetbrains.com/toolbox/download/' -H 'Connection: keep-alive' -H 'DNT: 1' --compressed | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}'| sed 's/[", ]//g');
echo $URL;
}
getLatestUrl &> /dev/null;

FILE=$(basename ${URL});
DEST=$PWD/$FILE;

wget -cO  ${DEST} ${URL} --read-timeout=5 --tries=0 &> /dev/null;
DIR="/opt/jetbrains-toolbox";
if sudo mkdir ${DIR}  &> /dev/null; 
then
    sudo tar -xzf ${DEST} -C ${DIR} --strip-components=1  &> /dev/null;
fi

sudo chmod -R +rwx ${DIR}  &> /dev/null;

sudo ln -s ${DIR}/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox  &> /dev/null;
sudo chmod -R +rwx /usr/local/bin/jetbrains-toolbox  &> /dev/null;
rm ${DEST}  &> /dev/null;
# end jetbrains toolbox install script

## Rust
echo "2.2.6. Installing Rust toolchain...";
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh &> /dev/null;
rustup update &> /dev/null;
rustup component add clippy &> /dev/null;
rustup component add rustfmt &> /dev/null;

# Configuration
echo "3. Configuration";

## Keyboard on boot
echo "3.1. Keyboard layout"
    # Configure encrypted boot default keyboard layout 
    # Configure display manager default keyboard layout
    
## GNOME
echo "3.2. GNOME";
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" &> /dev/null;
    # Tap to click
    # Terminal keyboard shortcut
    # GNOME Extensions: AppIndicator and KStatusNotifierItem Support = ON
    # gnome tweaks: autostart protonvpn
    # gnome tweaks top bar weekday, seconds, week numbers
## Git
echo "3.3. Git";    
    # Git config

## Sudo
echo "3.4. Sudo"
    # Defaults insults

## Firefox
echo "3.5. Firefox"
    # Firefox settings:
    #   - resistFingerprinting=true in about:config
    #   - restore previous session
    #   - check spelling as you type: no
    #   - homepage and new windows: blank page
    #   - new tabs: blank page
    #   - search engine: duck duck go
    #   - suggestions: no
    #   - privacy: custom - cross-site cookies, isolate other, trackers in all windows
    #   - do not track: always
    #   - ask to save logins: no
    #   - address bar: history, bookmarks
    #   - firefox data collection and use: turn all off
    #   - 
    #   - recommend extensions: no
    #   - 
echo "4. Script finished running.";

echo "5. For the remaining tasks, manual action is required:";

echo "5.1. Setup";
echo " - Copy the .ssh folder from backup";
echo " - Run jetbrains-toolbox";
echo " - Change Jetbrains Toolbox settings to not autostart on boot";
echo " - Install IntelliJ IDEA";
echo " - Install IntelliJ plugin 'rust'";
echo " - Change IntelliJ settings to use Clippy and Cargo Check: https://plugins.jetbrains.com/plugin/8182-rust/docs/rust-code-analysis.html#external-linters";
echo " - Change IntelliJ settings to use Rustfmt: https://plugins.jetbrains.com/plugin/8182-rust/docs/rust-code-style-and-formatting.html";
echo " - Change Lyx settings to display source code (View > Code preview pane > on, Code preview pane > Complete Source)";
echo " - Change Xournal++ settings to dark mode (Edit > Preferences > View > Dark Theme)";
echo " - Change Xournal++ default paper to a dark mode variant";

echo "5.2. Logins";
echo " - Log in to Proton VPN";
echo " - Log in to Proton Mail Bridge";
echo " - Log in to Mozilla Thunderbird: https://proton.me/support/protonmail-bridge-clients-windows-thunderbird";
echo " - Log in to Webcord (Discord)";
echo " - Log in to Nextcloud for school";
echo " - Log in to Anki";
