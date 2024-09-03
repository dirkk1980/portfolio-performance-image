# Pull base image.
FROM jlesage/baseimage-gui:debian-12-v4

ARG VERSION=0.70.3
ENV ARCHIVE=https://github.com/buchen/portfolio/releases/download/${VERSION}/PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz
ENV APP_ICON_URL=https://www.portfolio-performance.info/images/logo.png


RUN apt-get update && apt-get install -y wget && \
    cd /opt && wget ${ARCHIVE} && tar xvzf PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz && \
    rm PortfolioPerformance-${VERSION}-linux.gtk.x86_64.tar.gz

# Install dependencies.
RUN \
    apt-get install -y \
    openjdk-17-jre \
    libwebkit2gtk-4.1-0 \
    firefox-esr \
    xfce4 \
    thunar \
    tint2 \
    gsimplecal && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN \
    # Write config entry for new data folder, cause otherwise pp would try to write in /dev which is not possible
    echo "-data\n/config/portfolio\n$(cat /opt/portfolio/PortfolioPerformance.ini)" > /opt/portfolio/PortfolioPerformance.ini && \
    # Set initial language to english
    echo "osgi.nl=en" >> /opt/portfolio/configuration/config.ini && \
    chmod -R 777 /opt/portfolio && \
    install_app_icon.sh "$APP_ICON_URL"

# Set the name of the application.
ENV APP_NAME="Portfolio Performance"        

# Copy the start script.
COPY rootfs/ /

# Prepare folder for a default Firefox profile
RUN mkdir -p /root/.mozilla/firefox && \
    chmod -R 777 /root/.mozilla/firefox

# Create /etc/firefox/policies if it does not exist
RUN mkdir -p /usr/lib/firefox-esr/distribution && \
    echo '{"policies":{"OverrideFirstRunPage":"duckduckgo.com","OverridePostUpdatePage":"duckduckgo.com","ExtensionSettings":{"uBlock0@raymondhill.net":{"installation_mode":"force_installed","install_url":"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"}}}}' > /usr/lib/firefox-esr/distribution/policies.json

# Remove items from tint2 config to prevent error messages on startup as the applications are not installed
RUN sed -i '/launcher_item_app = tint2conf.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i '/launcher_item_app = firefox.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i '/launcher_item_app = iceweasel.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i '/launcher_item_app = chromium-browser.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i '/launcher_item_app = google-chrome.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i '/launcher_item_app = x-terminal-emulator.desktop/d' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    # Activate autohide for taskbar
    sed -i 's/autohide = 0/autohide = 1/g' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i 's/autohide_show_timeout = 0.3/autohide_show_timeout = 0.0/g' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i 's/autohide_hide_timeout = 2/autohide_hide_timeout = 2/g' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i 's/autohide_height = 2/autohide_height = 10/g' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    # Add program items to taskbar
    echo "launcher_item_app = /usr/share/applications/xfce4-file-manager.desktop" >> /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    echo "launcher_item_app = /usr/share/applications/firefox-esr.desktop" >> /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    # Change mouse actions for taskbar
    sed -i 's/mouse_middle = close/mouse_middle = toggle/g' /usr/share/tint2/vertical-neutral-icons.tint2rc && \
    sed -i 's/mouse_right = maximize_restore/mouse_right = close/g' /usr/share/tint2/vertical-neutral-icons.tint2rc

# Install dbus to improve compatibility with firefox
RUN apt-get update && apt-get install -y dbus dbus-x11 && apt-get clean && rm -rf /var/lib/apt/lists/*