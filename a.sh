#!/bin/bash
# Copyright 2023 aqz/tamaina, joinmisskey
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
version="3.2.0_srgr0";

#About this script
tput setaf 4;
echo "";
echo "Misskey setup script for Ubuntu";
echo "v$version";
echo "";

#Check environment(linux, root, arch)
function envtest() {
    tput setaf 2; echo "Checking environment..."; tput setaf 7;
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

#Select options
function options() {
    #---reg: Install method---
    tput setaf 3; echo "Install Method"; tput setaf 7;

    #Install method
    echo "Which method do you want to use to install Misskey?";
    echo "D = Use Docker Hub / b = Build a Docker image / s = Use Systemd";
    read -r -p "[D/b/s] > " dbs;
    case "$dbs" in
        [bB])
            #Docker build
            echo "Build a Docker image.";
            method="docker_build";
            ;;
        [sS])
            #Systemd
            echo "Use Systemd.";
            method="systemd";
            ;;
        *)
            #Docker Hub
            echo "Use Docker Hub.";
            method="docker_hub";
            ;;
    esac
    #---end-reg---

    echo "";

    #---reg: Misskey setting---
    tput setaf 3; echo "Misskey setting"; tput setaf 7;

    #Git/Docker Repository
    if [ $method = "docker_hub" ]; then
        echo "Enter repository:tag of Docker Hub image:";
        read -r -p "> " -e -i "misskey/misskey:latest" docker_repository;
        misskey_directory=misskey;
    else
        if [ $method = "docker_build" ]; then
            docker_repository="local/misskey:latest";
        fi
        echo "Enter repository url where you want to install:";
        read -r -p "> " -e -i "https://github.com/misskey-dev/misskey.git" git_repository;
        echo "Enther the branch or tag";
        read -r -p "> " -e -i "master" git_branch;
        echo "Enter the name of a new directory to clone:";
        read -r -p "> " -e -i "misskey" misskey_directory;
    fi

    echo "";

    #Username
    echo "Enter the name of user with which you want to execute Misskey:";
    read -r -p "> " -e -i "misskey" misskey_user;

    echo "";

    #Hostname
    echo "Enter host where you want to install Misskey:";
    read -r -p "> " -e -i "example.com" host;
    hostarr=(${host//./ });
    echo "OK, let's install $host!";

    echo "";

    #Port
    echo "Enter the port number you want to use for Misskey:";
    read -r -p "> " -e -i "3000" misskey_port;
    #---end-reg---

    echo "";

    #---reg: Nginx setting---
    tput setaf 3; echo "Nginx setting"; tput setaf 7;

    #Nginx(including certbot)
    echo "Do you want to setup nginx?:";
    read -r -p "[Y/n] > " yn;
    case "$yn" in
        [nN])
            #Not to install nginx
            echo "Nginx and Let's encrypt certificate will not be installed.";
            echo "You should open ports manually.";
            nginx_local=false;
            certbot=false;
            ;;
        *)
            #Install nginx
            echo "Nginx will be installed on this computer.";
            echo "Port 80 and 443 will be opened by modifying iptables.";
            nginx_local=true;

            echo "";

            #Method to open ports
            echo "Do you want it to open ports, to setup ufw or iptables?:";
            echo "u = To setup ufw / i = To setup iptables / N = Not to open ports";
            read -r -p "[u/i/N] > " yn2;
            case "$yn2" in
                [uU])
                    #ufw
                    echo "OK, it will use ufw.";
                    ufw=true;
                    iptables=false;
                    echo "SSH port: ";
                    read -r -p "> " -e -i "22" ssh_port;
                    ;;
                [iI])
                    #iptables
                    echo "OK, it will use iptables.";
                    ufw=false;
                    iptables=true;
                    echo "SSH port: ";
                    read -r -p "> " -e -i "22" ssh_port;
                    ;;
                *)
                    #Not to open ports
                    echo "OK, you should open ports manually.";
                    ufw=false;
                    iptables=false;
                    ;;
            esac

            echo "";

            #---sub-reg: Certbot setting---
            tput setaf 3; echo "Certbot setting"; tput setaf 7;

            #Certbot
            echo "Do you want it to setup certbot to connect with https?:";
            read -r -p "[Y/n] > " yn2;
            case "$yn2" in
                [nN])
                    #Not to use certbot
                    certbot=false;
                    echo "OK, you don't setup certbot.";
                    ;;
                *)
                    #Use certbot
                    certbot=true;
                    echo "OK, you want to setup certbot.";
                    ;;
            esac

            echo "";

            #Method to verify domain
            if [ $certbot = true ]; then
                echo "Do you use Cloudflare DNS?:";
                read -r -p "[Y/n] > " yn3;
                case "$yn3" in
                    [nN])
                        #Not to use Cloudflare DNS
                        certbot_dns_cloudflare=false;
                        certbot_http=true;
                        echo "OK, you don't use Cloudflare.";
                        echo "";
                        echo "The domain is authenticated by http challenge. ";
                        echo "Make sure that your DNS is configured to this machine.";

                        echo "";

                        echo "Enter Email address to register Let's Encrypt certificate";
                        read -r -p "> " certbot_mailaddress;
                        ;;
                    *)
                        #Use Cloudflare DNS
                        certbot_dns_cloudflare=true;
                        certbot_http=false;
                        echo "OK, you want to use Cloudflare DNS. Let's set up Cloudflare DNS.";
                        echo "";
                        echo "The domain is authenticated by DNS challenge. ";
                        echo "Make sure that Cloudflare DNS is configured and is in proxy mode.";

                        echo "";

                        echo "Enter Email address you registered to Cloudflare:";
                        echo "It also used to register Let's Encrypt certificate";
                        read -r -p "> " certbot_cloudflare_mail;
                        echo "Open https://dash.cloudflare.com/profile/api-tokens to get Global API Key and enter here it.";
                        echo "Cloudflare API Key: ";
                        read -r -p "> " certbot_cloudflare_key;

                        mkdir -p /etc/cloudflare;
                        cat > /etc/cloudflare/cloudflare.ini <<-_EOF
                        dns_cloudflare_email = $certbot_cloudflare_mail
                        dns_cloudflare_api_key = $certbot_cloudflare_key
_EOF

                        chmod 600 /etc/cloudflare/cloudflare.ini;
                        ;;
                esac
            fi
            #---end-sub-reg---

    fi
    #---end-reg---

    echo "";

    #---reg: Database (PostgreSQl) setting---
    tput setaf 3; echo "Database (PostgreSQL) setting"; tput setaf 7;

    #PostgreSQL
    echo "Do you want to install postgres locally?:";
    echo "(If you have run this script before in this computer, choose n and enter values you have set.)";
    read -r -p "[Y/n] > " yn
    case "$yn" in
        [nN])
            #Not to install postgres locally
            echo "You should prepare postgres manually until database is created.";
            db_local=false;

            echo "Database host: ";
            read -r -p "> " -e -i "$misskey_localhost" db_host;
            echo "Database port:";
            read -r -p "> " -e -i "5432" db_port;
            ;;
        *)
            #Install postgres locally
            echo "PostgreSQL will be installed on this computer at $misskey_localhost:5432.";
            db_local=true;

            db_host=$misskey_localhost;
            db_port=5432;
            ;;
    esac

    #Database user name and password, database name
    echo "Database user name: ";
    read -r -p "> " -e -i "misskey" db_user;
    echo "Database user password: ";
    read -r -p "> " db_pass;
    echo "Database name:";
    read -r -p "> " -e -i "mk1" db_name;
    #---end-reg---

    echo "";

    #---reg: Redis setting---
    tput setaf 3; echo "Redis setting"; tput setaf 7;

    #Redis
    echo "Do you want to install redis locally?:";
    echo "(If you have run this script before in this computer, choose n and enter values you have set.)"
    read -r -p "[Y/n] > " yn
    case "$yn" in
        [nN])
            #Not to install redis locally
            echo "You should prepare Redis manually.";
            redis_local=false;

            echo "Redis host:";
            read -r -p "> " -e -i "$misskey_localhost" redis_host;
            echo "Redis port:";
            read -r -p "> " -e -i "6379" redis_port;
            ;;
        *)
            #Install redis locally
            echo "Redis will be installed on this computer at $misskey_localhost:6379.";
            redis_local=true;

            redis_host=$misskey_localhost;
            redis_port=6379;
            ;;
    esac

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

        echo "This computer doesn't have enough RAM (>= 3GB, Current ${mem_allarr[1]}GB).";
        echo "Do you want to make swap?:";
        read -r -p "[Y/n] > " yn;
        case "$yn" in
            [nN])
                #Not to make swap
                echo "OK, you don't make swap. But the system may not work properly.";
                swap=false;
                ;;
            *)
                #Make swap
                echo "OK, you make swap.";
                swap=true;
                swap_size=(3 - "${mem_allarr[1]}")*1024;
                echo "Swap size: ${swap_size}MB";
                ;;
        esac
    fi
    #---end-reg---
}

#Confirm options
function confirm_options() {
    tput setaf 3; echo "Confirm"; tput setaf 7;

    #---reg: Install method---
    echo "Install method: $method";
    #---end-reg---

    #---reg: Misskey setting---
    if [ $method = "docker_hub" ]; then
        echo "Docker Repository: $docker_repository";
    else
        echo "Git Repository: $git_repository";
        echo "Git branch or tag: $git_branch";
        echo "Misskey directory: $misskey_directory";
    fi
    echo "Misskey user: $misskey_user";
    echo "Host: $host";
    echo "Misskey port: $misskey_port";
    #---end-reg---

    #---reg: Nginx setting---
    echo "Nginx: $nginx_local";
    if [ $nginx_local = true ]; then
        echo "UFW: $ufw";
        echo "iptables: $iptables";
        echo "Certbot: $certbot";
        if [ $certbot = true ]; then
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
    if [ $swap = true ]; then
        echo "Swap size: ${swap_size}MB";
    fi
    #---end-reg---

    echo "";

    if [ $skip_confirm != true ]; then
        echo "Is this correct? [Y/n]";
        read -r -p "> " yn;
        case "$yn" in
            [nN])
                #Not to install
                echo "OK, you don't install Misskey.";
                echo "if you want to change options and install Misskey, run this script again.";
                exit 1;
                ;;
            *)
                #Install
                echo "OK, let's install Misskey!";
                ;;
        esac
    fi
}

#Install Misskey
function install() {
}


function main() {
    envtest;
    #if envか因数があればoptionsをスキップ
    options;
    confirm_options;
}

main;