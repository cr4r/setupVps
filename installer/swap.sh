buatVariabelCode() {
  while [[ ${ukuran} = "" ]]; do
    read -p "$(msg -ama "Ukuran swap:") " ukuran
    tput cuu1 && tput dl1
  done
  msg -ama "Ukuran swap yang akan dibuat: $ukuran"
}

buatSwap() {
  fallocate -l "$ukuran"G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  editFileFstab
  msg -ama "Swap telah diaktifkan"
  msg -ama "Jika dibawah ini ada swap, artinya berhasil"
  swapon --show
}

editFileFstab() {
  if [[ $(grep -c "/swapfile swap swap defaults 0 0" /etc/fstab) -eq 0 ]]; then
    echo "/swapfile swap swap defaults 0 0" >>/etc/fstab
  fi
}

buatVariabelCode
buatSwap