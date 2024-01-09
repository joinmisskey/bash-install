#!/bin/bash -eu

#
# Copyright 2023 aqz/tamaina, Srgr0, joinmisskey
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#Version of this script
version="4.0.0-beta.1";
NODE_MAJOR="20";

#About this script
tput setaf 4;
echo "";
echo "Misskey setup script for Ubuntu";
echo "v$version";
echo "";

#Check environment(linux, root, arch)
function envtest() {
    echo "";
    tput setaf 3; echo "Checking environment..."; tput setaf 7;

    #Check if the script is running on Linux
    tput setaf 2; echo -n "Linux; "; tput setaf 7;
    if [ "$(command -v uname)" ]; then
        if [ "$(uname -s)" == "Linux" ]; then
            echo "    OK.";
            if ! [ -f "/etc/lsb-release" ]; then
                echo "	Warning: This script has been tested on Ubuntu and may not work on other distributions.";
            fi
        else
            tput setaf 1; echo "    NG. This script must be run on Linux.";
            exit 1;
        fi
    else
        tput setaf 1;
        echo "	NG.";
        exit 1;
    fi

    #Check if the script is running as root
    tput setaf 2; echo -n "root; "; tput setaf 7;
    if [ "$(whoami)" != 'root' ]; then
        tput setaf 1; echo "    NG. This script must be run as root.";
        exit 1;
    else
        echo "    OK.";
    fi

    #Check architecture
    tput setaf 2; echo -n "arch;"; tput setaf 7;
    case $(uname -m) in
        x86_64)
            echo "    x86_64 (amd64)";
            arch=amd64;
            ;;
        aarch64)
            echo "    aarch64 (arm64)";
            arch=arm64;
            ;;
        *)
            tput setaf 1; echo "    NG. $(uname -m) is unsupported architecture.";
            exit 1;
            ;;
    esac
}

#Load options
function load_options() {
    echo "";
    tput setaf 3; echo "Loading options from "${args[1]}"..."; tput setaf 7;

    #Load options
    source "${args[1]}";

    #Set docker host ip address
    if [ "$method" = "docker_hub" ] || [ "$method" = "docker_build" ]; then
        if [ "$docker_host_ip" = "auto" ] || [ "$docker_host_ip" = "Auto" ]; then
            echo "Setting docker host IP...";
            docker_host_ip="$(hostname -I | cut -f1 -d' ')";
            echo "Docker host IP: $docker_host_ip";
        fi
    fi

    #Check if the options are valid
    #Install method
    if [ "$method" != "docker_hub" ] && [ "$method" != "docker_build" ] && [ "$method" != "systemd" ]; then
        tput setaf 1; echo "Error: method is invalid."; tput setaf 7;
        exit 1;
    fi

    #Misskey setting
    if [ "$method" = "docker_hub" ]; then
        if [ -z "$docker_repository" ]; then
            tput setaf 1; echo "Error: docker_repository is not set."; tput setaf 7;
            exit 1;
        fi
        if [ -z "$docker_host_ip" ]; then
            tput setaf 1; echo "Error: docker_host_ip is not set."; tput setaf 7;
            exit 1;
        fi
    else
        if [ -z "$git_repository" ]; then
            tput setaf 1; echo "Error: git_repository is not set."; tput setaf 7;
            exit 1;
        fi
        if [ -z "$git_branch" ]; then
            tput setaf 1; echo "Error: git_branch is not set."; tput setaf 7;
            exit 1;
        fi
        if [ -z "$misskey_directory" ]; then
            tput setaf 1; echo "Error: misskey_directory is not set."; tput setaf 7;
            exit 1;
        fi
    fi
    if [ -z "$misskey_localhost" ]; then
        tput setaf 1; echo "Error: misskey_localhost is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$misskey_user" ]; then
        tput setaf 1; echo "Error: misskey_user is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$host" ]; then
        tput setaf 1; echo "Error: host is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$misskey_port" ]; then
        tput setaf 1; echo "Error: misskey_port is not set."; tput setaf 7;
        exit 1;
    fi

    #Cloudflare Tunnel/Nginx setting
    if [ "$cloudflaretunnel" != true ] && [ "$cloudflaretunnel" != false ]; then
        tput setaf 1; echo "Error: cloudflaretunnel is invalid."; tput setaf 7;
        exit 1;
    fi
    if $cloudflaretunnel; then
        if [ -z "$cf_apikey" ]; then
            tput setaf 1; echo "Error: cf_apikey is not set."; tput setaf 7;
            exit 1;
        fi
        if [ -z "$cfaccount_id" ]; then
            tput setaf 1; echo "Error: cfaccount_id is not set."; tput setaf 7;
            exit 1;
        fi
        if [ -z "$cfzone_id" ]; then
            tput setaf 1; echo "Error: cfzone_id is not set."; tput setaf 7;
            exit 1;
        fi
    fi
    if [ "$nginx_local" != true ] && [ "$nginx_local" != false ]; then
        tput setaf 1; echo "Error: nginx_local is invalid."; tput setaf 7;
        exit 1;
    fi
    if $nginx_local; then
        if [ "$ufw" != true ] && [ "$ufw" != false ]; then
            tput setaf 1; echo "Error: ufw is invalid."; tput setaf 7;
            exit 1;
        fi
        if [ "$iptables" != true ] && [ "$iptables" != false ]; then
            tput setaf 1; echo "Error: iptables is invalid."; tput setaf 7;
            exit 1;
        fi
        if [ "$certbot" != true ] && [ "$certbot" != false ]; then
            tput setaf 1; echo "Error: certbot is invalid."; tput setaf 7;
            exit 1;
        fi
        if $certbot; then
            if [ "$certbot_dns_cloudflare" != true ] && [ "$certbot_dns_cloudflare" != false ]; then
                tput setaf 1; echo "Error: certbot_dns_cloudflare is invalid."; tput setaf 7;
                exit 1;
            fi
            if [ "$certbot_http" != true ] && [ "$certbot_http" != false ]; then
                tput setaf 1; echo "Error: certbot_http is invalid."; tput setaf 7;
                exit 1;
            fi
            if $certbot_dns_cloudflare; then
                if [ -z "$certbot_cloudflare_mail" ]; then
                    tput setaf 1; echo "Error: certbot_cloudflare_mail is not set."; tput setaf 7;
                    exit 1;
                fi
                if [ -z "$certbot_cloudflare_key" ]; then
                    tput setaf 1; echo "Error: certbot_cloudflare_key is not set."; tput setaf 7;
                    exit 1;
                fi
            else
                if [ -z "$certbot_mailaddress" ]; then
                    tput setaf 1; echo "Error: certbot_mailaddress is not set."; tput setaf 7;
                    exit 1;
                fi
            fi
        fi
    fi

    #Database (PostgreSQL) setting
    if [ "$db_local" != true ] && [ "$db_local" != false ]; then
        tput setaf 1; echo "Error: db_local is invalid."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$db_host" ]; then
        tput setaf 1; echo "Error: db_host is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$db_port" ]; then
        tput setaf 1; echo "Error: db_port is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$db_user" ]; then
        tput setaf 1; echo "Error: db_user is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$db_pass" ]; then
        tput setaf 1; echo "Error: db_pass is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$db_name" ]; then
        tput setaf 1; echo "Error: db_name is not set."; tput setaf 7;
        exit 1;
    fi

    #Redis setting
    if [ "$redis_local" != true ] && [ "$redis_local" != false ]; then
        tput setaf 1; echo "Error: redis_local is invalid."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$redis_host" ]; then
        tput setaf 1; echo "Error: redis_host is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$redis_port" ]; then
        tput setaf 1; echo "Error: redis_port is not set."; tput setaf 7;
        exit 1;
    fi
    if [ -z "$redis_pass" ]; then
        tput setaf 1; echo "Error: redis_pass is not set."; tput setaf 7;
        exit 1;
    fi

    #Swap setting
    if [ "$swap" != true ] && [ "$swap" != false ]; then
        tput setaf 1; echo "Error: swap is invalid."; tput setaf 7;
        exit 1;
    fi
    if $swap; then
        if [ -z "$swap_size" ]; then
            tput setaf 1; echo "Error: swap_size is not set."; tput setaf 7;
            exit 1;
        fi
    fi

    #Install setting
    if [ "$skip_confirm" != true ] && [ "$skip_confirm" != false ]; then
        tput setaf 1; echo "Error: skip_confirm is invalid."; tput setaf 7;
        exit 1;
    fi
    if [ "$github_actions" != true ] && [ "$github_actions" != false ]; then
        tput setaf 1; echo "Error: github_actions is invalid."; tput setaf 7;
        exit 1;
    fi
}

#Save options
function save_options() {
    echo "";
    tput setaf 3; echo "Saving options to ./misskey_compose.txt..."; tput setaf 7;

    #Temporarily allow undefined variables
    set +u;
    cat > ./misskey_compose.txt <<-EOF
	#Install method
	method=$method

	#Misskey setting
	docker_repository=$docker_repository
	docker_host_ip=$docker_host_ip
	git_repository=$git_repository
	git_branch=$git_branch
	misskey_directory=$misskey_directory
	misskey_localhost=$misskey_localhost
	misskey_user=$misskey_user
	host=$host
	misskey_port=$misskey_port

	#Cloudflare Tunnel/Nginx setting
	cloudflaretunnel=$cloudflaretunnel
	ufw=$ufw
	iptables=$iptables
	certbot=$certbot
	certbot_dns_cloudflare=$certbot_dns_cloudflare
	certbot_http=$certbot_http
	certbot_mailaddress=$certbot_mailaddress
	certbot_cloudflare_mail=$certbot_cloudflare_mail
	certbot_cloudflare_key=$certbot_cloudflare_key

	#Database (PostgreSQL) setting
	db_local=$db_local
	db_host=$db_host
	db_port=$db_port
	db_user=$db_user
	db_pass=$db_pass
	db_name=$db_name

	#Redis setting
	redis_local=$redis_local
	redis_host=$redis_host
	redis_port=$redis_port
	redis_pass=$redis_pass

	#Swap setting
	swap=$swap
	swap_size=$swap_size

	#Install setting
	skip_confirm=false
	github_actions=false
	EOF
    #Disallow undefined variables again
    set -u;
}

#Select options
function options() {
    echo "";
    tput setaf 3; echo "Select options."; tput setaf 7;

    #---reg: Install method---
    tput setaf 3; echo "Install Method"; tput setaf 7;

    #Install method
    while true; do
        echo "Which method do you want to use to install Misskey?";
        echo "D = Use Docker Hub / b = Build a Docker image / s = Use Systemd";
        read -r -p "[D/b/s] > " dbs;

        case "$dbs" in
            [bB])
                # Docker build
                echo "Build a Docker image.";
                method="docker_build";
                misskey_localhost="docker_host";
                break
                ;;
            [sS])
                # Systemd
                echo "Use Systemd.";
                method="systemd";
                misskey_localhost=localhost;
                break
                ;;
            [dD])
                # Docker Hub
                echo "Use Docker Hub.";
                method="docker_hub";
                misskey_localhost="docker_host";
                break
                ;;
            *)
                # Invalid input
                echo "Invalid input, please choose 'D', 'b', or 's'.";
                ;;
        esac
    done

    if [ $method = "docker_hub" ] || [ $method = "docker_build" ]; then
        echo "Determine the local IP of this computer as docker host.";
        echo "The IPs that are supposed to be available are as follows (the result of hostname -I)";
        echo "	$(hostname -I)"
        read -r -p "> " -e -i "$(hostname -I | cut -f1 -d' ')" docker_host_ip;
    fi
    #---end-reg---

    echo "";

    #---reg: Misskey setting---
    tput setaf 3; echo "Misskey setting"; tput setaf 7;

    #Username
    echo "Enter the name of user with which you want to execute Misskey:";
    read -r -p "> " -e -i "misskey" misskey_user;

    echo "";

    #Git/Docker Repository
    if [ $method = "docker_hub" ]; then
        echo "Enter repository:tag of Docker Hub image:";
        read -r -p "> " -e -i "misskey/misskey:latest" docker_repository;
        misskey_directory=/home/$misskey_user/misskey;
    else
        if [ $method = "docker_build" ]; then
            docker_repository="local/misskey:latest";
            misskey_directory=/home/$misskey_user/misskey;
        fi
        echo "Enter repository url where you want to install:";
        read -r -p "> " -e -i "https://github.com/misskey-dev/misskey.git" git_repository;
        echo "Enther the branch or tag";
        read -r -p "> " -e -i "master" git_branch;
        echo "Enter the name of a new directory to clone:";
        read -r -p "> " -e -i "misskey" misskey_directory_path;
        misskey_directory=/home/$misskey_user/$misskey_directory_path;
    fi

    echo "";

    #Hostname
    echo "Enter host where you want to install Misskey:";
    read -r -p "> " -e -i "misskey.example.com" host;
    hostarr=(${host//./ });
    echo "OK, let's install $host!";

    echo "";

    #Port
    echo "Enter the port number you want to use for Misskey:";
    read -r -p "> " -e -i "3000" misskey_port;
    #---end-reg---

    echo "";

    #---reg: Cloudflare Tunnel/Nginx setting---
    tput setaf 3; echo "Cloudflare Tunnel/Nginx setting"; tput setaf 7;

    #Cloudflare Tunnel/Nginx
    while true; do
        echo "Do you want to setup Cloudflare Tunnel or Nginx?:";
        echo "C = Use Cloudflare Tunnel / g = Use Nginx / n = Don't use both";
        read -r -p "[C/g/n] > " cgn;

        case "$cgn" in
            [cC])
                # Cloudflare Tunnel
                echo "Cloudflare Tunnel will be installed.";
                cloudflaretunnel=true;
                nginx_local=false;
                break
                ;;
            [gG])
                # Nginx
                echo "Nginx will be installed.";
                cloudflaretunnel=false;
                nginx_local=true;
                break
                ;;
            [nN])
                # Not to use both
                echo "Don't use both.";
                cloudflaretunnel=false;
                nginx_local=false;
                break
                ;;
            *)
                # Invalid input
                echo "Invalid input, please choose 'C', 'g', or 'n'.";
                ;;
        esac
    done

    echo "";

    #---sub-reg: Cloudflare Tunnel setting---
    if $cloudflaretunnel; then
        echo "Some information is required to setup Cloudflare Tunnel.";
        echo "Please check the details at https://github.com/joinmisskey/bash-install/blob/v4/README.md and prepare the required information.";

        echo "Enter your Cloudflare API key:";
        read -r -p "> " cf_apikey;
        echo "Enter your Cloudflare Account ID:";
        read -r -p "> " -e cfaccount_id;
        echo "Enter your Cloudflare Zone ID:";
        read -r -p "> " -e cfzone_id;
    fi
    #---end-sub-reg---

    #---sub-reg: Nginx setting---
    if $nginx_local; then
        #Method to open ports
        while true; do
            echo "Do you want it to open ports, to setup ufw or iptables?:";
            echo "u = To setup ufw / i = To setup iptables / N = Not to open ports";
            read -r -p "[u/i/N] > " yn2;

            case "$yn2" in
                [uU])
                    # ufw
                    echo "OK, it will use ufw.";
                    ufw=true;
                    iptables=false;
                    echo "SSH port: ";
                    read -r -p "> " -e -i "22" ssh_port;
                    break
                    ;;
                [iI])
                    # iptables
                    echo "OK, it will use iptables.";
                    ufw=false;
                    iptables=true;
                    echo "SSH port: ";
                    read -r -p "> " -e -i "22" ssh_port;
                    break
                    ;;
                [nN])
                    # Not to open ports
                    echo "OK, you should open ports manually.";
                    ufw=false;
                    iptables=false;
                    break
                    ;;
                *)
                    # 無効な入力
                    echo "Invalid input, please choose 'u', 'i', or 'N'.";
                    ;;
            esac
        done

        echo "";

        #---sub2-reg: Certbot setting---
        tput setaf 3; echo "Certbot setting"; tput setaf 7;

        #Certbot
        while true; do
            echo "Do you want it to setup certbot to connect with https?:";
            read -r -p "[Y/n] > " yn2;

            case "$yn2" in
                [yY])
                    # Use certbot
                    certbot=true;
                    echo "OK, you want to setup certbot.";
                    break
                    ;;
                [nN])
                    # Not to use certbot
                    certbot=false;
                    echo "OK, you don't setup certbot.";
                    break
                    ;;
                *)
                    # Invalid input
                    echo "Invalid input, please choose 'Y' or 'n'.";
                    ;;
            esac
        done

        echo "";

        #Method to verify domain
        if $certbot; then
            while true; do
                echo "Do you use Cloudflare DNS API?:";
                read -r -p "[Y/n] > " yn3;

                case "$yn3" in
                    [nN])
                        # Not to use Cloudflare DNS
                        certbot_dns_cloudflare=false;
                        certbot_http=true;
                        echo "OK, you don't use Cloudflare.";
                        echo "";
                        echo "The domain is authenticated by http challenge.";
                        echo "Make sure that your DNS is configured to this machine.";

                        echo "";

                        echo "Enter Email address to register Let's Encrypt certificate";
                        read -r -p "> " certbot_mailaddress;
                        break
                        ;;
                    [yY])
                        # Use Cloudflare DNS
                        certbot_dns_cloudflare=true;
                        certbot_http=false;
                        echo "OK, you want to use Cloudflare DNS. Let's set up Cloudflare DNS.";
                        echo "";
                        echo "The domain is authenticated by DNS challenge.";
                        echo "Make sure that Cloudflare DNS is configured and is in proxy mode.";

                        echo "";

                        echo "Enter Email address you registered to Cloudflare:";
                        echo "It also used to register Let's Encrypt certificate";
                        read -r -p "> " certbot_cloudflare_mail;
                        echo "Open https://dash.cloudflare.com/profile/api-tokens to get Global API Key and enter here it.";
                        echo "Cloudflare API Key: ";
                        read -r -p "> " certbot_cloudflare_key;

                        mkdir -p /etc/cloudflare;
                        cat > /etc/cloudflare/cloudflare.ini <<-EOF
						dns_cloudflare_email = $certbot_cloudflare_mail
						dns_cloudflare_api_key = $certbot_cloudflare_key
						EOF
                        #↑tab indent

                        chmod 600 /etc/cloudflare/cloudflare.ini;
                        break
                        ;;
                    *)
                        # Invalid input
                        echo "Invalid input, please choose 'Y' or 'n'.";
                        ;;
                esac
            done
        fi
        #---end-sub2-reg---
    fi
    #---end-sub-reg---
    #---end-reg---

    echo "";

    #---reg: Database (PostgreSQl) setting---
    tput setaf 3; echo "Database (PostgreSQL) setting"; tput setaf 7;

    #PostgreSQL
    while true; do
        echo "Do you want to install postgres locally?:";
        echo "(If you have run this script before in this computer, choose n and enter values you have set.)";
        read -r -p "[Y/n] > " yn

        case "$yn" in
            [nN])
                # Not to install postgres locally
                echo "You should prepare postgres manually until database is created.";
                db_local=false;

                echo "Database host: ";
                read -r -p "> " -e -i "$misskey_localhost" db_host;
                echo "Database port:";
                read -r -p "> " -e -i "5432" db_port;
                break
                ;;
            [yY])
                # Install postgres locally
                echo "PostgreSQL will be installed on this computer at $misskey_localhost:5432.";
                db_local=true;

                db_host=$misskey_localhost;
                db_port=5432;
                break
                ;;
            *)
                # Invalid input
                echo "Invalid input, please choose 'Y' or 'n'.";
                ;;
        esac
    done

    #Database user name and password, database name
    echo "Database user name: ";
    read -r -p "> " -e -i "misskey" db_user;
    echo "Database user password: ";
    read -r -p "> " db_pass;
    echo "Database name:";
    read -r -p "> " -e -i "misskey" db_name;
    #---end-reg---

    echo "";

    #---reg: Redis setting---
    tput setaf 3; echo "Redis setting"; tput setaf 7;

    #Redis
    while true; do
        echo "Do you want to install redis locally?:";
        echo "(If you have run this script before in this computer, choose n and enter values you have set.)"
        read -r -p "[Y/n] > " yn

        case "$yn" in
            [nN])
                # Not to install redis locally
                echo "You should prepare Redis manually.";
                redis_local=false;

                echo "Redis host:";
                read -r -p "> " -e -i "$misskey_localhost" redis_host;
                echo "Redis port:";
                read -r -p "> " -e -i "6379" redis_port;
                break
                ;;
            [yY])
                # Install redis locally
                echo "Redis will be installed on this computer at $misskey_localhost:6379.";
                redis_local=true;

                redis_host=$misskey_localhost;
                redis_port=6379;
                break
                ;;
            *)
                # 無効な入力
                echo "Invalid input, please choose 'Y' or 'n'.";
                ;;
        esac
    done

    #Redis password
    echo "Redis password:";
    read -r -p "> " redis_pass;
    #---end-reg---

    #---reg: Swap setting---
    #Only if the memory is less than 3GB
    mem_all=$(free -t --si -g | tail -n 1);
    mem_allarr=(${mem_all//\\t/ });
    mem_swap=$(free | tail -n 1);
    mem_swaparr=(${mem_swap//\\t/ });
    if [ "${mem_allarr[1]}" -lt 3 ]; then
        tput setaf 3; echo "Swap setting"; tput setaf 7;

        while true; do
            echo "This computer doesn't have enough RAM (>= 3GB, Current ${mem_allarr[1]}GB).";
            echo "Do you want to make swap?:";
            read -r -p "[Y/n] > " yn;

            case "$yn" in
                [yY])
                    # Make swap
                    echo "OK, you make swap.";
                    swap=true;
                    swap_size=$((3 - "${mem_allarr[1]}"))*1024;
                    echo "Swap size: ${swap_size}MB";
                    break
                    ;;
                [nN])
                    # Not to make swap
                    echo "OK, you don't make swap. But the system may not work properly.";
                    swap=false;
                    break
                    ;;
                *)
                    # Invalid input
                    echo "Invalid input, please choose 'Y' or 'n'.";
                    ;;
            esac
        done
    else
        #Need not to make swap
        swap=false;
    fi
    #---end-reg---

    #---reg: Install setting---
    skip_confirm=false
    github_actions=false
    #---end-reg---
}

#Confirm options
function confirm_options() {
    echo "";
    tput setaf 3; echo "Confirm options."; tput setaf 7;

    #---reg: Install method---
    echo "Install method: $method";
    #---end-reg---

    #---reg: Misskey setting---
    if [ $method = "docker_hub" ]; then
        echo "Docker Repository: $docker_repository";
        echo "Docker host IP: $docker_host_ip";
    else
        echo "Git Repository: $git_repository";
        echo "Git branch or tag: $git_branch";
        echo "Misskey directory: $misskey_directory";
    fi
    echo "Misskey localhost: $misskey_localhost";
    echo "Misskey user: $misskey_user";
    echo "Host: $host";
    echo "Misskey port: $misskey_port";
    #---end-reg---

    #---reg: Cloudflare Tunnel/Nginx setting---
    echo "Cloudflare Tunnel: $cloudflaretunnel";
    if $cloudflaretunnel; then
        echo "Cloudflare API key: **********";
        echo "Cloudflare Account ID: $cfaccount_id";
        echo "Cloudflare Zone ID: $cfzone_id";
    fi

    echo "Nginx: $nginx_local";
    if $nginx_local; then
        echo "UFW: $ufw";
        echo "iptables: $iptables";
        echo "Certbot: $certbot";
        if $certbot; then
            echo "Certbot DNS_Cloudflare: $certbot_dns_cloudflare";
            echo "Certbot HTTP: $certbot_http";
            if [ $certbot_dns_cloudflare = true ]; then
                echo "Certbot Cloudflare mail: $certbot_cloudflare_mail";
                echo "Certbot Cloudflare key: **********";
            else
                echo "Certbot mailaddress: $certbot_mailaddress";
            fi
        fi
    fi
    #---end-reg---

    #---reg: Database (PostgreSQL) setting---
    echo "PostgreSQL: $db_local";
    echo "Database host: $db_host";
    echo "Database port: $db_port";
    echo "Database user: $db_user";
    echo "Database password: **********";
    echo "Database name: $db_name";
    #---end-reg---

    #---reg: Redis setting---
    echo "Redis: $redis_local";
    echo "Redis host: $redis_host";
    echo "Redis port: $redis_port";
    echo "Redis password: **********";
    #---end-reg---

    #---reg: Swap setting---
    echo "Swap: $swap";
    if $swap; then
        echo "Swap size: ${swap_size}MB";
    fi
    #---end-reg---

    #---reg: Install setting---
    echo "skip_confirm: $skip_confirm"
    echo "github_actions: $github_actions"
    #---end-reg---

    echo "";

    #Confirm options if skip_confirm is not true
    if [ $skip_confirm != true ]; then
        while true; do
            echo "Is this correct? [Y/n]";
            read -r -p "> " yn;

            case "$yn" in
                [yY])
                    # Install
                    echo "OK, let's install Misskey!";
                    break
                    ;;
                [nN])
                    # Not to install
                    echo "OK, you don't install Misskey.";
                    echo "if you want to change options and install Misskey, run this script again.";
                    exit 1
                    ;;
                *)
                    # 無効な入力
                    echo "Invalid input, please choose 'Y' or 'n'.";
                    ;;
            esac
        done
    fi
}

#Install Misskey
function install() {
    echo "";
    tput setaf 3; echo "Install Misskey."; tput setaf 7;

    #Check if Misskey is already installed
    if [ -f "/root/.misskey_installed" ]; then
        tput setaf 1; echo "Error: Misskey is marked as already installed."; tput setaf 7;
        echo "if you want to install Misskey forcibly, delete /root/.misskey_installed.";
        exit 1;
    fi
    touch /root/.misskey_installed;

    #Install Packeges
    function install_packages() {
        echo "";
        tput setaf 3; echo "Process: apt install #1;"; tput setaf 7;

        apt -qq update -y;
        apt -qq install -y curl nano jq gnupg2 apt-transport-https ca-certificates lsb-release software-properties-common uidmap$($certbot && echo " certbot")$($nginx_local && ($ufw && echo " ufw" || $iptables && echo " iptables-persistent"))$($certbot_dns_cloudflare && echo " python3-certbot-dns-cloudflare")$([ $method != "docker_hub" ] && echo " git")$([ $method == "systemd" ] && echo " ffmpeg build-essential");
    }

    #Create a user to run Misskey
    function add_user() {
        echo "";
        tput setaf 3; echo "Process: add misskey user ($misskey_user);"; tput setaf 7;

        if ! id -u "$misskey_user" > /dev/null 2>&1; then
            useradd -m -U -s /bin/bash "$misskey_user";
        else
            echo "Error: $misskey_user already exists.";
        fi
        echo "misskey_user=\"$misskey_user\"" > /root/.misskey.env
        echo "version=\"$version\"" >> /root/.misskey.env
        m_uid=$(id -u "$misskey_user")
    }

    #Delete Misskey directory if exists
    function delete_misskey_directory() {
        echo "";
        tput setaf 3; echo "Process: delete misskey directory ($misskey_directory);"; tput setaf 7;

        if [ -e "$misskey_directory" ]; then
            rm -rf "$misskey_directory";
        fi
    }

    #Clone git repository
    function git_clone() {
        echo "";
        tput setaf 3; echo "Process: clone git repository;"; tput setaf 7;

        if [[ $git_repository == local_* ]]; then
            cp -r ${git_repository#local_} "$misskey_directory";
        else
            sudo -iu "$misskey_user" git clone -b "$git_branch" --depth 1 --recursive "$git_repository" "$misskey_directory";
        fi
    }

    #Create misskey config file
    function create_config() {
        echo "";
        tput setaf 3; echo "Process: create config;"; tput setaf 7;

        sudo -iu "$misskey_user" mkdir -p "$misskey_directory/.config";

        sudo -iu "$misskey_user" cat > "$misskey_directory/.config/default.yml" <<-EOF
		url: https://$host
		port: $misskey_port

		# PostgreSQL
		db:
		  host: '$db_host'
		  port: $db_port
		  db  : '$db_name'
		  user: '$db_user'
		  pass: '$db_pass'

		# Redis
		redis:
		  host: '$redis_host'
		  port: $redis_port
		  pass: '$redis_pass'

		# ID type
		id: 'aid'

		# Proxy remote files (default: true)
		# Proxy remote files by this instance or mediaProxy to prevent remote files from running in remote domains.
		proxyRemoteFiles: true

		# Sign to ActivityPub GET request (default: true)
		signToActivityPubGet: true

		proxyBypassHosts:
		  - api.deepl.com
		  - api-free.deepl.com
		  - www.recaptcha.net
		  - hcaptcha.com
		  - challenges.cloudflare.com
		  - summaly.arkjp.net
		EOF
    }

    #Open ports
    function open_ports() {
        echo "";
        tput setaf 3; echo "Process: open ports;"; tput setaf 7;

        #ufw
        if $ufw; then
            ufe default deny;
            ufw allow "$ssh_port/tcp";
            ufw allow 80;
            ufw allow 443;
            ufw --force enable;
            ufw status;
        fi

        #iptables
        if $iptables; then
            if iptables -C INPUT -p tcp --dport "$ssh_port" -j ACCEPT &> /dev/null; then
                echo "iptables rule for port $ssh_port already exists"
            else
                iptables -I INPUT -p tcp --dport "$ssh_port" -j ACCEPT
                echo "iptables rule for port $ssh_port added"
            fi

            if iptables -C INPUT -p tcp --dport 80 -j ACCEPT &> /dev/null; then
                echo "iptables rule for port 80 already exists"
            else
                iptables -I INPUT -p tcp --dport 80 -j ACCEPT
                echo "iptables rule for port 80 added"
            fi

            if iptables -C INPUT -p tcp --dport 443 -j ACCEPT &> /dev/null; then
                echo "iptables rule for port 443 already exists"
            else
                iptables -I INPUT -p tcp --dport 443 -j ACCEPT
                echo "iptables rule for port 443 added"
            fi

            if ip6tables -C INPUT -p tcp --dport "$ssh_port" -j ACCEPT &> /dev/null; then
                echo "ip6tables rule for port $ssh_port already exists"
            else
                ip6tables -I INPUT -p tcp --dport "$ssh_port" -j ACCEPT
                echo "ip6tables rule for port $ssh_port added"
            fi

            if ip6tables -C INPUT -p tcp --dport 80 -j ACCEPT &> /dev/null; then
                echo "ip6tables rule for port 80 already exists"
            else
                ip6tables -I INPUT -p tcp --dport 80 -j ACCEPT
                echo "ip6tables rule for port 80 added"
            fi

            if ip6tables -C INPUT -p tcp --dport 443 -j ACCEPT &> /dev/null; then
                echo "ip6tables rule for port 443 already exists"
            else
                ip6tables -I INPUT -p tcp --dport 443 -j ACCEPT
                echo "ip6tables rule for port 443 added"
            fi

            iptables-save > /etc/iptables/rules.v4
            ip6tables-save > /etc/iptables/rules.v6
            iptables -L;
            ip6tables -L;
        fi
    }

    #Setup Cloudflare Tunnel
    function setup_cloudflaretunnel() {
        echo "";
        tput setaf 3; echo "Process: setup Cloudflare Tunnel;"; tput setaf 7;

        # Set variables
        service=http://127.0.0.1:$misskey_port;


        # Verify API key
        response=$(curl -s -X GET -w "%{http_code}" \
                -H "Authorization: Bearer $cf_apikey" \
                -H "Content-Type: application/json" \
                "https://api.cloudflare.com/client/v4/user/tokens/verify");

        if [ "$response" -ne 200 ]; then
            echo "Invalid API key.";
            exit 1;
        fi

        # Create tunnel
        cftunnel_name="Misskey_$(date +%Y-%m-%d-%H-%M-%S)";
        create_tunnel_response=$(curl -s -X POST \
                                -H "Authorization: Bearer $cf_apikey" \
                                -H "Content-Type: application/json" \
                                --data "{\"name\":\"$cftunnel_name\",\"config_src\":\"cloudflare\"}" \
                                "https://api.cloudflare.com/client/v4/accounts/$cfaccount_id/cfd_tunnel");
        cftunnel_id=$(echo $create_tunnel_response | jq -r '.result.id');

        # Create DNS record
        create_dns_record_response=$(curl --request POST \
                                        --url https://api.cloudflare.com/client/v4/zones/$cfzone_id/dns_records \
                                        -H "Authorization: Bearer $cf_apikey" \
                                        -H "Content-Type: application/json" \
                                        --data "{\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$host\",\"content\":\"$cftunnel_id.cfargotunnel.com\"}"
        );

        # Set hostnames to tunnel
        update_tunnel_response=$(curl --request PUT \
                                --url https://api.cloudflare.com/client/v4/accounts/$cfaccount_id/cfd_tunnel/$cftunnel_id/configurations \
                                -H "Authorization: Bearer $cf_apikey" \
                                -H "Content-Type: application/json" \
                                --data "{\"config\":{\"ingress\":[{\"hostname\":\"$host\",\"service\":\"$service\"},{\"service\":\"http_status:404\"}]}}"
        );

        # Get token
        get_token_response=$(curl -s -X GET \
                                --url https://api.cloudflare.com/client/v4/accounts/$cfaccount_id/cfd_tunnel/$cftunnel_id/token \
                                -H "Authorization: Bearer $cf_apikey" \
                                -H "Content-Type: application/json" \
        );
        cftunnel_token=$(echo $get_token_response | jq -r '.result');

        # Install cloudflared
        if [ "arch" = "arm64" ]; then
            echo "Architecture: arm64";
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb;
            sudo dpkg -i cloudflared-linux-arm64.deb;
        else
            echo "Architecture: amd64";
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb;
            sudo dpkg -i cloudflared-linux-amd64.deb;
        fi

        # Setup tunnel service
        sudo cloudflared service install $cftunnel_token;
    }

    #Install Nginx
    function prepare_nginx() {
        echo "";
        tput setaf 3; echo "Process: prepare nginx;"; tput setaf 7;

        #Add nginx gpg key
        curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null;

        #Check nginx gpg key
        if gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg | grep -q 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; then
            echo "OK. nginx gpg key is valid.";
        else
            tput setaf 1; echo "Error: nginx gpg key is invalid."; tput setaf 7;
            exit 1;
        fi

        #Setup nginx repository
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list;
        echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx;

        #Install nginx
        apt -qq update -y;
        apt -qq install -y nginx;

        #Check version
        tput setaf 3;
        echo "Nginx version:";
        nginx -v;
        tput setaf 7;
    }

    #Install Nodejs
    function prepare_nodejs() {
        echo "";
        tput setaf 3; echo "Process: prepare nodejs;"; tput setaf 7;

        #In GitHub Actions, remove nodejs 18
        if $github_actions; then
            apt -qq remove -y nodejs;
            rm -rf /usr/local/bin/npm /usr/local/bin/node /usr/local/lib/node_modules;
        fi

        #Add nodejs gpg key
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg;
        echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list;

        #Install nodejs
        apt -qq update -y;
        apt -qq install -y nodejs libjemalloc-dev;

        #Check version
        tput setaf 3;
        echo "Nodejs version:";
        node -v;
        which node;
        tput setaf 7;

        #Enable corepack
        corepack enable;

        #Check version
        tput setaf 3;
        echo "Corepack version:";
        corepack -v;
        echo "pnpm version:";
        pnpm -v;
        tput setaf 7;
    }

    #Install Docker
    function prepare_docker() {
        echo "";
        tput setaf 3; echo "Process: prepare docker;"; tput setaf 7;

        #Add docker gpg key
        if ! [ -e /usr/share/keyrings/docker-archive-keyring.gpg ]; then
            curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        fi

        #Setup docker repository
        echo "deb [arch=$arch signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        #Install docker
        apt -qq update -y;
        apt install -qq -y docker-ce docker-ce-cli containerd.io;

        #Check version
        tput setaf 3;
        echo "Docker version:";
        docker --version;
        tput setaf 7;
    }

    #Install Redis
    function prepare_redis() {
        echo "";
        tput setaf 3; echo "Process: prepare redis;"; tput setaf 7;

        #Add redis gpg key
        curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg;

        #Setup redis repository
        echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list;

        #Install redis
        apt -qq update -y;
        apt -qq install -y redis;

        #Check version
        tput setaf 3;
        echo "Redis version:";
        redis-server --version;
        tput setaf 7;
    }

    #Install PostgreSQL
    function prepare_postgresql() {
        echo "";
        tput setaf 3; echo "Process: prepare postgresql;"; tput setaf 7;

        #Install postgresql
        apt -qq install -y postgresql-common;

        #Setup
        sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v 15;

        #Check version
        tput setaf 3;
        echo "PostgreSQL version:";
        psql --version;
        tput setaf 7;
    }

    #Create DB and user
    function create_db() {
        echo "";
        tput setaf 3; echo "Process: create db and user;"; tput setaf 7;

        #Start postgresql
        service postgresql start

        #Create user
        sudo -iu postgres psql -c "CREATE ROLE $db_user LOGIN PASSWORD '$db_pass';";

        #Create database
        sudo -iu postgres psql -c "CREATE DATABASE $db_name OWNER $db_user;";
    }

    #Setup Redis
    function setup_redis() {
        echo "";

        #Activate Redis daemon
        tput setaf 3; echo "Process: activate redis daemon;"; tput setaf 7;
        systemctl start redis-server;
        systemctl enable redis-server;

        #Create Redis config file
        tput setaf 3; echo "Process: create redis config file;"; tput setaf 7;
        if [ -f /etc/redis/redis.conf ]; then
            echo "requirepass $redis_pass" > /etc/redis/misskey.conf
            [ $method != "systemd" ] && echo "bind $docker_host_ip" >> /etc/redis/misskey.conf

            if ! grep "include /etc/redis/misskey.conf" /etc/redis/redis.conf; then
                echo "include /etc/redis/misskey.conf" >> /etc/redis/redis.conf;
            else
                echo "	skip"
            fi
        else
            echo "Couldn't find /etc/redis/redis.conf."
            echo "Please modify redis config in another shell like following."
            echo ""
            echo "requirepass $redis_pass"
            [ $method != "systemd" ] && echo "bind $docker_host_ip"
            echo ""
            read -r -p "Press Enter key to continue> "
        fi

        #Restart Redis daemon
        systemctl restart redis-server;
    }

    #Setup Nginx
    function setup_nginx() {
        echo "";

        if $certbot; then
            #With certbot(https & http)
            #Create nginx config file for http
            tput setaf 3; echo "Process: create nginx config file for http;"; tput setaf 7;

            cat > "/etc/nginx/conf.d/$host.conf" <<-EOF
			# nginx configuration for Misskey
			# Created by joinmisskey/bash-install v$version

			# For WebSocket
			map \$http_upgrade \$connection_upgrade {
				default upgrade;
				''      close;
			}

			proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=cache1:16m max_size=1g inactive=720m use_temp_path=off;

			server {
				listen 80;
				listen [::]:80;
				server_name $host;

				# For SSL domain validation
				root /var/www/html;
				location /.well-known/acme-challenge/ { allow all; }
				location /.well-known/pki-validation/ { allow all; }

				# with https
				location / { return 301 https://\$server_name\$request_uri; }
			}
			EOF

            #Get certificate
            tput setaf 3; echo "Process: get certificate;"; tput setaf 7;

            nginx -t;
            systemctl restart nginx;
            if $cloudflare; then
                certbot certonly -t -n --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare/cloudflare.ini --dns-cloudflare-propagation-seconds 60 --server https://acme-v02.api.letsencrypt.org/directory $([ ${#hostarr[*]} -eq 2 ] && echo " -d $host -d *.$host" || echo " -d $host") -m "$cf_mail";
            else
                mkdir -p /var/www/html;
                certbot certonly -t -n --agree-tos --webroot --webroot-path /var/www/html $([ ${#hostarr[*]} -eq 2 ] && echo " -d $host" || echo " -d $host") -m "$cf_mail";
            fi

            #Modify nginx config file for https
            tput setaf 3; echo "Process: edit nginx config file for https;"; tput setaf 7;

            cat > "/etc/nginx/conf.d/$host.conf" <<-EOF
			server {
				listen 443 ssl http2;
				listen [::]:443 ssl http2;
				server_name $host;

				ssl_session_timeout 1d;
				ssl_session_cache shared:ssl_session_cache:10m;
				ssl_session_tickets off;

				# To use Let's Encrypt certificate
				ssl_certificate     /etc/letsencrypt/live/$host/fullchain.pem;
				ssl_certificate_key /etc/letsencrypt/live/$host/privkey.pem;

				# SSL protocol settings
				ssl_protocols TLSv1.2 TLSv1.3;
				ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
				ssl_prefer_server_ciphers off;
				ssl_stapling on;
				ssl_stapling_verify on;

				# Change to your upload limit
				client_max_body_size 80m;

				# Proxy to Node
				location / {
					proxy_pass http://127.0.0.1:$misskey_port;
					proxy_set_header Host \$host;
					proxy_http_version 1.1;
					proxy_redirect off;

					$($certbot_dns_cloudflare || echo "# If it's behind another reverse proxy or CDN, remove the following.")
					$($certbot_dns_cloudflare || echo "proxy_set_header X-Real-IP \$remote_addr;")
					$($certbot_dns_cloudflare || echo "proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;")
					$($certbot_dns_cloudflare || echo "proxy_set_header X-Forwarded-Proto https;")

				# For WebSocket
				proxy_set_header Upgrade \$http_upgrade;
				proxy_set_header Connection \$connection_upgrade;

				# Cache settings
				proxy_cache cache1;
				proxy_cache_lock on;
				proxy_cache_use_stale updating;
				proxy_force_ranges on;
				add_header X-Cache \$upstream_cache_status;
				EOF

        else
            #Not with certbot(http only)
            #Create nginx config file for http
            tput setaf 3; echo "Process: create nginx config file;"; tput setaf 7;

            cat > "/etc/nginx/conf.d/$host.conf" <<-EOF
			# nginx configuration for Misskey
			# Created by joinmisskey/bash-install v$version

			# For WebSocket
			map \$http_upgrade \$connection_upgrade {
				default upgrade;
				''      close;
			}

			proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=cache1:16m max_size=1g inactive=720m use_temp_path=off;

			server {
				listen 80;
				listen [::]:80;
				server_name $host;

				# For SSL domain validation
				root /var/www/html;
				location /.well-known/acme-challenge/ { allow all; }
				location /.well-known/pki-validation/ { allow all; }

				# Change to your upload limit
				client_max_body_size 80m;

				# Proxy to Node
				location / {
					proxy_pass http://127.0.0.1:$misskey_port;
					proxy_set_header Host \$host;
					proxy_http_version 1.1;
					proxy_redirect off;

					# If it's behind another reverse proxy or CDN, remove the following.
					proxy_set_header X-Real-IP \$remote_addr;
					proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
					proxy_set_header X-Forwarded-Proto https;

					# For WebSocket
					proxy_set_header Upgrade \$http_upgrade;
					proxy_set_header Connection \$connection_upgrade;

					# Cache settings
					proxy_cache cache1;
					proxy_cache_lock on;
					proxy_cache_use_stale updating;
					proxy_force_ranges on;
					add_header X-Cache \$upstream_cache_status;
                }
			}
			EOF
        fi

        #Check config
        tput setaf 3; echo "Process: check nginx config;"; tput setaf 7;
        nginx -t;

        #Activate nginx daemon
        tput setaf 3; echo "Process: activate nginx daemon;"; tput setaf 7;
        systemctl restart nginx;
        systemctl enable nginx;

        #Check response
        tput setaf 3; echo "Process: check response;"; tput setaf 7;
        if curl http://localhost | grep -q nginx; then
            echo "	OK.";
        else
            tput setaf 1; echo "	NG.";
            exit 1;
        fi
    }

    #Setup Docker
    function setup_docker() {
        echo "";

        #Enable rootless docker
        tput setaf 3; echo "Process: use rootless docker;"; tput setaf 7;
        systemctl disable --now docker.service docker.socket
        loginctl enable-linger "$misskey_user"
        sleep 5
        sudo -iu "$misskey_user" <<-EOF
		set -eu;
		cd ~;
		export XDG_RUNTIME_DIR=/run/user/$m_uid;
		export DOCKER_HOST=unix:///run/user/$m_uid/docker.sock;
		systemctl --user --no-pager
		dockerd-rootless-setuptool.sh install
		docker ps;
		EOF

        #Modify postgresql config
        if $db_local; then
            tput setaf 3; echo "Process: modify postgres confs;" tput setaf 7;
            #hba file
            pg_hba=$(sudo -iu postgres psql -t -P format=unaligned -c 'show hba_file')
            #config file
            pg_conf=$(sudo -iu postgres psql -t -P format=unaligned -c 'show config_file')
            #docker host ip
            [[ $(ip addr | grep "$docker_host_ip") =~ /([0-9]+) ]] && subnet=${BASH_REMATCH[1]};

            #Check hba file and add a line if not exists
            hba_text="host $db_name $db_user $docker_host_ip/$subnet md5"
            if ! grep "$hba_text" "$pg_hba"; then
                echo "$hba_text" >> "$pg_hba";
            fi

            #Check config file and edit a line if not exists
            pgconf_search="#listen_addresses = 'localhost'"
            pgconf_text="listen_addresses = '$docker_host_ip'"
            if grep "$pgconf_search" "$pg_conf"; then
                sed -i'.mkmoded' -e "s/$pgconf_search/$pgconf_text/g" "$pg_conf";
            elif grep "$pgconf_text" "$pg_conf"; then
                echo "	skip"
            else
                echo "Please edit postgresql.conf to set [listen_addresses = '$docker_host_ip'] by your hand."
                read -r -p "Enter the editor command and press Enter key > " -e -i "nano" editorcmd
                $editorcmd "$pg_conf";
            fi
            systemctl restart postgresql;
        fi
    }

    #Setup Misskey for systemd
    function setup_misskey_systemd() {
        echo "";

        #Setup misskey
        tput setaf 3; echo "Process: setup misskey"; tput setaf 7;
        sudo -iu "$misskey_user" <<-EOF;
		set -eu;
		cd ~;
		cd "$misskey_directory";

		tput setaf 3; echo "Process: install npm packages"; tput setaf 7;
		NODE_ENV=production pnpm install --frozen-lockfile;

		tput setaf 3; echo "Process: build misskey"; tput setaf 7;
		NODE_OPTIONS=--max_old_space_size=3072 NODE_ENV=production pnpm run build;

		tput setaf 3; echo "Process: initialize database"; tput setaf 7;
		NODE_OPTIONS=--max_old_space_size=3072 pnpm run init;

		tput setaf 3; echo "Check: If Misskey starts correctly"; tput setaf 7;
		if NODE_ENV=production timeout 40 npm start 2> /dev/null | grep -q "Now listening on port"; then
			echo "	OK.";
		else
			tput setaf 1; echo "	NG.";
		fi
		EOF

        #Create misskey daemon
        tput setaf 3; echo "Process: create misskey daemon;" tput setaf 7;
        cat > "/etc/systemd/system/$host.service" <<-EOF;
		[Unit]
		Description=Misskey daemon

		[Service]
		Type=simple
		User=$misskey_user
		ExecStart=$(command -v npm) start
		WorkingDirectory=$misskey_directory
		Environment="NODE_ENV=production"
		Environment="LD_PRELOAD=/usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2"
		TimeoutSec=60
		StandardOutput=journal
		StandardError=journal
		SyslogIdentifier="$host"
		Restart=always

		[Install]
		WantedBy=multi-user.target
		EOF

        #Enable misskey daemon
        tput setaf 3; echo "Process: enable misskey daemon;" tput setaf 7;
        systemctl daemon-reload;
        systemctl enable "$host";
        systemctl start "$host";
        systemctl status "$host" --no-pager;

        #Create .misskey.env
        tput setaf 3; echo "Process: create .misskey.env;" tput setaf 7;
        su "$misskey_user" <<-EOF
		set -eu;
		cd ~;

		cat > ".misskey.env" <<-_EOF
		host="$host"
		misskey_port=$misskey_port
		misskey_directory="$misskey_directory"
		misskey_localhost="$misskey_localhost"
		version="$version"
		_EOF
		EOF

        tput setaf 2;
        tput bold;
        echo "ALL MISSKEY INSTALLATION PROCESSES ARE COMPLETE!";
        echo "Jump to http://$host/ and continue setting up your instance.";
        tput setaf 7;
        echo "This script version is v$version.";
        echo "Please check https://github.com/joinmisskey/bash-install to address bugs and updates.";
    }

    #Setup Misskey for docker(docker_hub and docker_build)
    function setup_misskey_docker() {
        echo "";

        if [ $method == "docker_build" ]; then
            tput setaf 3; echo "Process: build docker image;"; tput setaf 7;
            sudo -iu "$misskey_user" XDG_RUNTIME_DIR=/run/user/$m_uid DOCKER_HOST=unix:///run/user/$m_uid/docker.sock docker build -t $docker_repository "$misskey_directory";
        fi

        #Run docker container
        tput setaf 3; echo "Process: docker run;"; tput setaf 7;
        sudo -iu "$misskey_user" mkdir -p "$misskey_directory/files";
        docker_container=$(sudo -iu "$misskey_user" XDG_RUNTIME_DIR=/run/user/$m_uid DOCKER_HOST=unix:///run/user/$m_uid/docker.sock docker run -d -p $misskey_port:$misskey_port --add-host=$misskey_localhost:$docker_host_ip -v "$misskey_directory/files":/misskey/files -v "$misskey_directory/.config/default.yml":/misskey/.config/default.yml:ro --restart unless-stopped -t "$docker_repository");
        echo "$docker_container";

        #Create .misskey-docker.env
        tput setaf 3; echo "Process: create misskey-docker.env;"; tput setaf 7;
        su "$misskey_user" <<-MKEOF
		set -eu;
		cd ~;

		cat > ".misskey-docker.env" <<-_EOF
		method="$method"
		host="$host"
		misskey_port=$misskey_port
		misskey_directory="$misskey_directory"
		misskey_localhost="$misskey_localhost"
		docker_host_ip=$docker_host_ip
		docker_repository="$docker_repository"
		docker_container="$docker_container"
		version="$version"
		_EOF
		MKEOF

        tput setaf 2;
        tput bold;
        echo "ALL MISSKEY INSTALLATION PROCESSES ARE COMPLETE!";
        echo "The setup process is currently running, takes a few minutes (depending on machine specs).";
        echo "";
        echo "You can check the setup progress with the following command:";
        echo "sudo -iu $misskey_user XDG_RUNTIME_DIR=/run/user/$m_uid DOCKER_HOST=unix:///run/user/$m_uid/docker.sock docker logs -f $docker_container";
        echo "";
        echo "After the setup is complete, jump to http://$host/ and continue setting up your instance.";
        echo "";
        tput setaf 7;
        echo "This script version is v$version.";
        echo "Please check https://github.com/joinmisskey/bash-install to address bugs and updates.";
    }

    #### Please do not change the order of the installation process. ####
    install_packages;
    add_user;
    delete_misskey_directory;
    if [ $method != "docker_hub" ]; then git_clone; fi
    create_config;
    if $nginx_local; then open_ports; prepare_nginx; fi
    if $cloudflaretunnel; then setup_cloudflaretunnel; fi
    if [ $method == "systemd" ]; then prepare_nodejs; fi
    if [ $method != "systemd" ]; then prepare_docker; fi
    if $redis_local; then prepare_redis; fi
    if $db_local; then prepare_postgresql; fi
    create_db;
    if $redis_local; then setup_redis; fi
    if $nginx_local; then setup_nginx; fi
    if [ $method != "systemd" ]; then setup_docker; fi
    if [ $method == "systemd" ]; then setup_misskey_systemd; else setup_misskey_docker; fi
}

#Main
function main() {
    args=("$@")

    #Check environment
    envtest;

    #Select options
    #If a yaml file is specified with the -c option, load the file. Otherwise, run options.
    if [ ${#args[@]} -eq 0 ]; then
        echo "Compose file is not specified. Select options interactively.";
        options;
    else
        if [ "${args[0]}" = "-c" ]; then
            if [ -f "${args[1]}" ]; then
                echo "Compose file is specified. Load options from "${args[1]}".";
                load_options;
            else
                tput setaf 1; echo "Error: "${args[1]}" is not found or is not a file.";
                exit 1;
            fi
        else
            tput setaf 1; echo "Invalid option.";
            options;
        fi
    fi

    #Confirm options
    confirm_options;

    #Save options
    save_options;

    #Install Misskey
    install;
}

main "$@";
