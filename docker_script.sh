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
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"


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
			echo -e "${Error} 当前账号非ROOT(或没有docker用户组权限)，如果没有docker用户组权限无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" 		
			exit 1
		fi
	fi
	
	}

check_docker(){
	docker_version=`docker version |grep version`
	if [ -z "$docker_version" ]; then
		echo -e "${Error} 当前系统并没有安装docker，无法继续操作，请使用以下命令进行安装:" 
		echo -e "${Green_background_prefix} sudo apt-get install curl"
		echo -e "${Green_background_prefix} curl -sSL https://get.docker.com/ | sh"
		exit 1
	fi
}

check_root_or_dockeruser
check_sys

if [ "$release" = "debian" ] || [ "$release" = "ubuntu" ] || [ "$release" = "centos" ]; then
echo "---------begin---------"
else
echo -e "${Error} 本脚本不支持当前系统 $release !" 
 exit 1
fi 




view_docker(){
	docker_view=`$1`
	echo "$docker_view"
	echo "                                  "
	echo && stty erase '^H' && read -p "输入数字0退出程序，其他键返回主菜单：" num
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
echo && stty erase '^H' && read -p "请确定新建虚拟机占用的端口(7080~7099)：" s_port
until [ "$s_port" -ge 7080 -a "$s_port" -le 7099 ] 2>/dev/null
   do
       echo "输入不正确，请输入7080 ~ 7099 之间的数字: "
       echo && stty erase '^H' && read -p "请重新输入：" s_port
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
     echo "新建虚拟机占用的端口号不能和现有虚拟机的重复!"
     input_port
     docker_view=`docker ps -a|grep $s_port`
done

sub_dir='/abc/'
until [ -d $sub_dir ] 
do
    echo "共享目录路径必须是主机真实有效的路径"
    echo && stty erase '^H' && read -p "请确定主机共享目录路径(输入'n'代表按照默认路径/media/)：" s_dir
	 case "$s_dir" in
	  'n')
	   sub_dir='/media/'
           ;;
	   *)
           echo "请输入主机共享路径，结尾以'/'结束"
	   sub_dir=$s_dir
	   ;;
         esac
done

#script="docker run -d -p $s_port:80 --shm-size 1g -v $sub_dir"
script="docker run -d --init --dns 114.114.114.114 -p $s_port:80 --shm-size 1g -v $sub_dir"

echo && stty erase '^H' && read -p "请为新建虚拟机命名(输入'n'代表由系统随机命名,命名遵从[a-zA-Z0-9][a-zA-Z0-9_.-])：" s_name
         case "$s_name" in
	  'n')
	   vnc_name=""
           ;;
	   *)
	   docker_view=`docker ps -a|grep $s_name`
	   until [ -z "$docker_view" ]
           do
             echo "新建虚拟机命名的名字不能和现有虚拟机名字重复！"
             echo && stty erase '^H' && read -p "请为新建虚拟机重新命名：" s_name
             docker_view=`docker ps -a|grep $s_name`
           done
           vnc_name=" --name $s_name"
	   ;;
         esac

sub_password=""
until [ -n "$sub_password" ]
do
echo "虚拟机需要配置非空密码"
echo && stty erase '^H' && read -p "请输入虚拟机密码：" s_p
sub_password=$s_p
done

if [ ! -n "$1" ] ;then
    image_code='labsys2.1'
else
    image_code=$1
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

echo "虚拟机 $container_id 已成功创建"

	echo && stty erase '^H' && read -p "输入数字0退出程序，其他键返回主菜单：" num
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
	   echo "尚未启动的容器如下："
           flag="启动"
	   f="start"
	   s=0
	elif [ $1 -eq 1 ]; then
	   docker_view=`docker ps`
           echo "当前正在运行的容器如下："
	   flag="停止"
	   f="stop"
	   s=1
	elif [ $1 -eq 2 ];then
	   docker_view=`docker ps -a|grep ed`
	   echo "可以删除的容器如下(只允许删除停止运行的容器)："
           flag="删除"
	   f="rm"
	   s=0
        elif [ $1 -eq 3 ]; then
           docker_view=`docker ps`
           echo "当前正在运行的容器如下："
           flag="重启"
           f="restart"
           s=1


	else
           menu_status
        fi

        if [ -f p.sctmp ]; then
	   rm p.sctmp
        fi
	if [ -f t.sctmp ]; then
	   rm t.sctmp
        fi

#	echo "$docker_view"
	echo "$docker_view">>p.sctmp
        vnt=`cat p.sctmp|wc -l`
	vnt=`expr $vnt - $s`

	echo "$docker_view">>t.sctmp
	if [ $s -eq 0 ];then
           title='CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS'
	   echo "        $title"
	else
	   title=`head -1 t.sctmp`
           echo "        $title"
           sed -i '1d' t.sctmp
        fi
	nl t.sctmp
	
	if [ -n "$docker_view" ]; then
	    echo && stty erase '^H' && read -p "容器序号 [1-$vnt],或输入0代表取消当前操作返回上级菜单：" num
        else
            echo "没有可以$flag的容器，即将返回上级菜单。"
	    echo ""
	    rm p.sctmp
            rm t.sctmp
            sleep 1
            menu_status
        fi

	case "$num" in
	   0)
           rm p.sctmp
	   rm t.sctmp
           menu_status
           ;;
           *)
	   until [ "$num" -ge 0 -a "$num" -le $vnt ] 2>/dev/null
	   do
                echo "输入不正确，请输入0,或1 ~ $vnt 之间的数字: "
		echo && stty erase '^H' && read -p "请输入：" num
	   done
        
	   case "$num" in
	      0)
              rm p.sctmp
	      rm t.sctmp
              menu_status
              ;;
              *)
              CONTAINER=`cat t.sctmp |awk 'NR=="'"$num"'"'|awk -F'        ' '{print $1}'`
#	      num=`expr $num + $s`	    
	      echo && stty erase '^H' && read -p "请确定是否$flag容器$CONTAINER(输入'y'代表确定，其他键代表放弃) ：" sc
	      case "$sc" in
	         'y')		
#	          cat p.sctmp| awk 'NR=="'"$num"'"' |while read CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                  PORTS                  NAMES
#	          do
	   	    echo "`docker $f $CONTAINER`"
                    echo "容器 $CONTAINER 已成功$flag !"
                    if [ $1 -eq 2 ];then
                       sed -i "/${CONTAINER}/d" vnc.info
		       vnt=`cat vnc.info|wc -l`
		       if [ $vnt -eq 0 ];then
			  rm vnc.info
		       fi
                    fi
#	          done
                  ;;
	         *)
	         echo "已取消$flag容器$CONTAINER"
	         ;;
              esac
              rm p.sctmp
	      rm t.sctmp
	      echo && stty erase '^H' && read -p "输入数字0退出程序，其他键返回主菜单：" num
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
echo -e "  Docker 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Bohrium.Kwong ----
  ${Green_font_prefix}1.${Font_color_suffix} 查看 docker版本
  ${Green_font_prefix}2.${Font_color_suffix} 查看 当前所有镜像
  ${Green_font_prefix}3.${Font_color_suffix} 查看 正在运行的容器
  ${Green_font_prefix}4.${Font_color_suffix} 查看 所有容器
  ————————————
  ${Green_font_prefix}5.${Font_color_suffix} 启动 容器
  ${Green_font_prefix}6.${Font_color_suffix} 关闭 容器
  ————————————
  ${Green_font_prefix}7.${Font_color_suffix} 新建 容器
  ${Green_font_prefix}8.${Font_color_suffix} 删除 容器
  ${Green_font_prefix}9.${Font_color_suffix} 重启 容器
  ————————————
  ${Green_font_prefix}0.${Font_color_suffix} 退出程序
 "
 
echo && stty erase '^H' && read -p "请输入数字 [0-9]：" num
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
	create_container $1
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
	echo -e "${Error} 请输入正确的数字 [0-9]"
	menu_status
	;;
esac
}
menu_status $1
