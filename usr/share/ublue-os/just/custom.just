!include /usr/share/ublue-os/just/bling.just

# install all flatpaks defined in recipe.yml
setup-flatpaks:
  #!/usr/bin/env bash
  echo 'Installing flatpaks from the ublue recipe ...'
  flatpaks=$(yq -- '.firstboot.flatpaks[]' "/usr/share/ublue-os/recipe.yml")
  for pkg in $flatpaks; do \
      echo "Installing: ${pkg}" && \
      flatpak install --user --noninteractive flathub $pkg; \
  done

# Include some of your custom scripts here!

setup-gaming:
  echo 'Setting up gaming experience ... lock and load.'
  flatpak override --user --env=MANGOHUD=1 com.valvesoftware.Steam

gamescope-nvidia:
  #!/usr/bin/env bash
  NVIDIA_VERSION=$(flatpak run --command=ls com.valvesoftware.Steam /usr/lib/x86_64-linux-gnu/GL/ | grep nvidia)
  flatpak override --user --env=GBM_BACKENDS_PATH="/usr/lib/x86_64-linux-gnu/GL/${NVIDIA_VERSION}/extra/gbm" com.valvesoftware.Steam

download-kitty:
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n

setup-kitty:
  #!/usr/bin/env bash
  just download-kitty
  # Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in
  # your system-wide PATH)
  ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
  # Place the kitty.desktop file somewhere it can be found by the OS
  cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
  # If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
  cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
  # Update the paths to the kitty and its icon in the kitty.desktop file(s)
  sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
  sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop

update:
  rpm-ostree update
  flatpak update -y
  distrobox upgrade -a
  just download-kitty

reboot:
  systemctl reboot
