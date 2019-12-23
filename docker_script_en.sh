#!/bin/sh
##################################################
#=================================================
#	System: CentOS 6+/Debian 6+/Ubuntu 16.04+
#	Description: Execute docker scripts
#       Date :2018-12-19
#	Author: Bohrium Kwong
#=================================================
##################################################


Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[infomation]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"
Tip="${Green_font_prefix}[warning]${Font_color_suffix}"


check_sys(){
	if [ -f /etc/redhat-release ]; then
		release="centos"
	elif cat /etc/issue | grep "debian"; then
		release="debian"
	elif cat /etc/issue | grep "Ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep "debian"; then
		release="debian"
	elif cat /proc/version | grep "Ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep "centos|red hat|redhat"; then
		release="centos"
        fi
	bit=`uname -m`
}

check_root_or_dockeruser(){
	user=$(env | grep USER= | cut -d "=" -f 2| awk 'NR==1')
	if [ "$user" != "root" ]; then
		user_right=`cat /etc/group|grep docker|grep $user`
		if [ -z "$user_right" ]; then
			echo -e "${Error} You are not logged as root or your account are not in docker user group ,it can't be countinued without docker user 's permission.Please use ${Green_background_prefix} sudo su ${Font_color_suffix}to run this script as root permission." 		
			exit 1
		fi
	fi
	
	}

check_docker(){
	docker_version=`docker version |grep version`
	if [ -z "$docker_version" ]; then
		echo -e "${Error} It can't be countinued since this system has not installed docker yet,please install docker with the following script:" 
		echo -e "${Green_background_prefix} sudo apt-get install curl"
		echo -e "${Green_background_prefix} curl -sSL https://get.docker.com/ | sh"
		exit 1
	fi
}

check_root
check_sys

if [ "$release" = "debian" ] || [ "$release" = "ubuntu" ] || [ "$release" = "centos" ]; then
echo "---------begin---------"
else
echo -e "${Error} The script is not match this system $release !" 
 exit 1
fi 




view_docker(){
	docker_view=`$1`
	echo "$docker_view"
	echo "                                  "
	echo && stty erase '^H' && read -p "Input numeral 0 to exit，other keys to return to home menu:" num
	case "$num" in
	 0)
	 exit 0
	 ;;
	 *)
	 menu_status
	 ;;
        esac
}

input_port(){
echo && stty erase '^H' && read -p "Please set the port of new VNC(6080~6099):" s_port
until [ "$s_port" -ge 6080 -a "$s_port" -le 6099 ] 2>/dev/null
   do
       echo "Input not correct,make sure the numeral you input is between 6080 and 6099: "
       echo && stty erase '^H' && read -p "Please input again:" s_port
   done
}


create_container(){
input_port
docker_view=`docker ps -a|grep $s_port`
if [ -f vnc.info ]; then
   vnc_t=`cat vnc.info|grep $s_port`
else
   vnc_t=''
fi	
until [ -z "$docker_view" ] && [ -z "$vnc_t" ]
   do
     echo "The port of new VNC can't be same as other VNC in use!"
     input_port
     docker_view=`docker ps -a|grep $s_port`
done

sub_dir='/abc/'
until [ -d $sub_dir ] 
do
    echo "Make sure the shared directories you set is a real path of this system."
    echo && stty erase '^H' && read -p "Set the directories you want to share(Input letter 'n' to set a default shared directories as /media/):" s_dir
	 case "$s_dir" in
	  'n')
	   sub_dir='/media/'
           ;;
	   *)
           echo "Please input absolute path,and ends with '/' "
	   sub_dir=$s_dir
	   ;;
         esac
done

script="docker run -d -p $s_port:80 --shm-size 1g -v $sub_dir"

echo && stty erase '^H' && read -p "Please name this new VNC(Input letter 'n' to generate by docker,the naming rules is [a-zA-Z0-9][a-zA-Z0-9_.-]):" s_name
         case "$s_name" in
	  'n')
	   vnc_name=""
           ;;
	   *)
	   docker_view=`docker ps -a|grep $s_name`
	   until [ -z "$docker_view" ]
           do
             echo "The name of new VNC can't be same as other VNC in use!"
             echo && stty erase '^H' && read -p "Please name it again :" s_name
             docker_view=`docker ps -a|grep $s_name`
           done
           vnc_name=" --name $s_name"
	   ;;
         esac

sub_password=""
until [ -n "$sub_password" ]
do
echo "The passward should be not null."
echo && stty erase '^H' && read -p "Please set the passward of new VNC: " s_p
sub_password=$s_p
done

if [ ! -n "$1" ] ;then
    image_code='f98d17213229'
else
    image_code = $1
fi

script="$script:/media$vnc_name --runtime=nvidia -e VNC_PASSWORD=$sub_password $image_code"

docker_view="`$script`"
#container_id=${docker_view:0:12}

a='a'
if [ -f vnc.info ]; then
    vnt=`cat vnc.info|wc -l`
    sed -i "$vnt$a$docker_view $s_port $sub_password" vnc.info
else
    echo "0$a$docker_view $s_port $sub_password">>vnc.info
fi

echo "VNC $container_id has been created successfully."

	echo && stty erase '^H' && read -p "Input numeral 0 to exit，other keys to return to home menu:" num
	case "$num" in
	 0)
	 exit 0
	 ;;
	 *)
	 menu_status
	 ;;
        esac
}

start_stop_delete_container(){
	if [ $1 -eq 0 ];then
	   docker_view=`docker ps -a|grep ted`
	   echo "Container which not be started as below:"
           flag="started"
	   f="start"
	   s=0
	elif [ $1 -eq 1 ]; then
	   docker_view=`docker ps`
           echo "Container which are running as below:"
	   flag="stopped"
	   f="stop"
	   s=1
	elif [ $1 -eq 2 ];then
	   docker_view=`docker ps -a|grep ed`
	   echo "Container which are not running can be removed as below:"
           flag="removed"
	   f="rm"
	   s=0
        elif [ $1 -eq 3 ]; then
           docker_view=`docker ps`
           echo "Container which are running as below:"
           flag="restarted"
           f="restart"
           s=1

	else
           menu_status
        fi

	if [ -f p.sctmp ]; then
	   rm p.sctmp
        fi

	echo "$docker_view"
	echo "$docker_view">>p.sctmp
        vnt=`cat p.sctmp|wc -l`
	vnt=`expr $vnt - $s`
	echo && stty erase '^H' && read -p "please input sequence number of the container [1-$vnt],or input 0 to return home menu :" num

	case "$num" in
	   0)
           menu_status
           ;;
           *)
	   until [ "$num" -ge 0 -a "$num" -le $vnt ] 2>/dev/null
	   do
                echo "Input not correct,make sure you input is 0 or the numeral between 1 and  $vnt :"
		echo && stty erase '^H' && read -p "Please input again: " num
	   done
        
	   case "$num" in
	      0)
              menu_status
              ;;
              *)
        
	      num=`expr $num + $s`
	      echo && stty erase '^H' && read -p "Are you sure to $f container(Input letter 'y' to execute,other keys to cancel) :" sc
	      case "$sc" in
	         'y')		
	          cat p.sctmp| awk 'NR=="'"$num"'"' |while read CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                  PORTS                  NAMES
	          do
	   	    echo "`docker $f $CONTAINER`"
                    echo "Container $CONTAINER has been $flag successfully!"
                    if [ $1 -eq 2 ];then
                       sed -i "/${CONTAINER}/d" vnc.info
		       vnt=`cat vnc.info|wc -l`
		       if [ $vnt -eq 0 ];then
			  rm vnc.info
		       fi
                    fi
	          done
                 ;;
	         *)
	         echo "Container will not be $flag,since the  operation has benn cancelled."
	         ;;
              esac
	      rm p.sctmp
	      echo && stty erase '^H' && read -p "Input numeral 0 to exit，other keys to return to home menu:" num
	      case "$num" in
	         0)
	         exit 0
	         ;;
	         *)
	         menu_status
	         ;;
              esac

           ;;
           esac

        ;;
        esac

}

menu_status(){
echo -e "  Docker Management Script ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Bohrium.Kwong ----

  ${Green_font_prefix}1.${Font_color_suffix} view docker version
  ${Green_font_prefix}2.${Font_color_suffix} view all images
  ${Green_font_prefix}3.${Font_color_suffix} view containers which are running
  ${Green_font_prefix}4.${Font_color_suffix} view all containers
  ————————————
  ${Green_font_prefix}5.${Font_color_suffix} start container
  ${Green_font_prefix}6.${Font_color_suffix} stop container
  ————————————
  ${Green_font_prefix}7.${Font_color_suffix} create container of VNC
  ${Green_font_prefix}8.${Font_color_suffix} remove container
  ${Green_font_prefix}9.${Font_color_suffix} restart container
  ————————————
  ${Green_font_prefix}0.${Font_color_suffix} exit
 "
 
echo && stty erase '^H' && read -p "Please input numeral [0-9]:" num
case "$num" in
	1)
	view_docker 'docker version'
	;;
	2)
	view_docker 'docker images'
	;;
	3)
	view_docker 'docker ps'	
	;;
	4)
	view_docker 'docker ps -a'
	;;
	5)
	start_stop_delete_container 0
	;;
	6)
	start_stop_delete_container 1
	;;
	7)
	create_container
	;;
	8)
	start_stop_delete_container 2
	;;
        9)
        start_stop_delete_container 3
        ;;
	0)
	exit 0
	;;
	*)
	echo -e "${Error} Please input numeral [0-9]:"
	menu_status
	;;
esac
}
menu_status		
