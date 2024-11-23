#!/bin/bash

while true; do
    OPTION=$(whiptail --title "Main Menu" --menu "Choose an option:" 20 70 13 \
                    "1" "Update System and Install Prerequisites" \
                    "2" "Install Docker" \
                    "3" "Install Wazuh (SIEM)" \
                    "4" "Install Shuffle (SOAR)" \
                    "5" "Install DFIR-IRIS (Incident Response Platform)" \
                    "6" "Install MISP" \
                    "7" "Setup IRIS <-> Wazuh Integration" \
                    "8" "Setup MISP <-> Wazuh Integration" \
                    "9" "Show Status" 3>&1 1>&2 2>&3)

    case $OPTION in
    1)
        sudo apt-get update -y
        sudo apt-get upgrade -y
        sudo apt-get install wget curl nano git unzip -y
        ;;
    2)
        # Check if Docker is installed
        if command -v docker > /dev/null; then
            echo "Docker is already installed."
        else
            # Install Docker
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo systemctl enable docker.service && sudo systemctl enable containerd.service
        fi
        ;;
    3)
        cd wazuh-docker
        cd single-node
        sudo docker network create shared-network
        sudo docker compose -f generate-indexer-certs.yml run --rm generator
        sudo docker compose up -d
        ;;
    4)
        cd Shuffle
        sudo chown -R 1000:1000 shuffle-database
        sudo docker compose up -d
        ;;
    5)
        cd iris-web
        sudo docker compose up -d
        ;;
    6)
        cd misp
        IP=$(curl -s ip.me -4)
        sed -i "s|BASE_URL=.*|BASE_URL='https://$IP:1443'|" template.env
        sudo docker compose up -d
        ;;
    7)
        sudo cp custom-integrations/custom-iris.py /var/lib/docker/volumes/single-node_wazuh_integrations/_data/custom-iris.py
        sudo docker exec -ti single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-iris.py
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-iris.py
        sudo docker exec -ti single-node-wazuh.manager-1 yum update -y
        sudo docker exec -ti single-node-wazuh.manager-1 yum install python3-pip -y
        sudo docker exec -ti single-node-wazuh.manager-1 pip3 install requests
        cd single-node && sudo docker compose restart
        ;;
    8)
        sudo cp custom-integrations/custom-misp.py /var/lib/docker/volumes/single-node_wazuh_integrations/_data/custom-misp.py
        sudo docker exec -ti single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-misp.py
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-misp.py
        cp custom-integrations/local_rules.xml /var/lib/docker/volumes/single-node_wazuh_etc/_data/rules/local_rules.xml
        sudo docker exec -ti single-node-wazuh.manager-1 chown wazuh:wazuh /var/lib/docker/volumes/single-node_wazuh_etc/_data/rules/local_rules.xml
        sudo docker exec -ti single-node-wazuh.manager-1 chmod 550 /var/lib/docker/volumes/single-node_wazuh_etc/_data/rules/local_rules.xml
        cd single-node && sudo docker compose restart
        ;;
    9)
        sudo docker ps
        ;;
esac
    # Give option to go back to the previous menu or exit
    if (whiptail --title "Exit" --yesno "Do you want to exit the script?" 8 78); then
        break
    else
        continue
    fi
done