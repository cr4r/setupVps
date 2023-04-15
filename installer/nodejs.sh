[[ $(dpkg --get-selections | grep -w "make" | head -1) ]] || (msg -ama "(1) Menginstall Module ..." && apt-get install make -y &>/dev/null && tput cuu1 && tput dl1)
[[ $(dpkg --get-selections | grep -w "build-essential" | head -1) ]] || (msg -ama "(1) Menginstall Module ..." && apt-get install build-essential -y &>/dev/null && tput cuu1 && tput dl1)
[[ $(dpkg --get-selections | grep -w "gcc" | head -1) ]] || (msg -ama "(1) Menginstall Module ..." && apt-get install gcc -y &>/dev/null && tput cuu1 && tput dl1)
[[ $(dpkg --get-selections | grep -w "g++" | head -1) ]] || (msg -ama "(1) Menginstall Module ..." && apt-get install g++ -y &>/dev/null && tput cuu1 && tput dl1)

msg -ama "Instalasi Nodejs Dimulai"
bash <(curl -L -s https://deb.nodesource.com/setup_19.x)
[[ $(dpkg --get-selections | grep -w "nodejs" | head -1) ]] || (msg -ama "(1) Menginstall Module ..." && apt-get install nodejs -y &>/dev/null && tput cuu1 && tput dl1)
msg -ama "Instalasi Nodejs Selesai"
msg -ama "Versi NodeJS $(node -v)"
msg -ama "Versi NPM $(npm -v)"
