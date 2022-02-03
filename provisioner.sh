#!/bin/bash

set -x

NUM_VMS=$1
HOME="/home/vagrant"
SYNCED_FOLDER="/vm_share"
SPARK_FOLDER="/usr/local/spark"

if [[ ! -e /etc/.provisioned ]]; then
	apt update
	# java をインストール
	apt install -y default-jdk
	echo 'JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"' >> /etc/environment
	# sbt をインストール
	echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
	echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
	apt update
	apt install -y sbt
	# apache spark をインストール
	curl -OL https://dlcdn.apache.org/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz
	tar -xvf spark-3.1.2-bin-hadoop3.2.tgz -C /usr/local
	rm -rf spark-3.1.2-bin-hadoop3.2.tgz
	mv /usr/local/spark-3.1.2-bin-hadoop3.2 $SPARK_FOLDER

	# /etc/hostsとsparkの設定
    for i in `seq 1 $NUM_VMS`; do
        ip="192.168.56.$((100+i))"
        echo "$ip node$i" >> /etc/hosts
        echo "node$i" >> $SPARK_FOLDER/conf/workers

		# マスターノードの場合
		if [[ i -eq 1 ]]; then
			cp $SPARK_FOLDER/conf/spark-env.sh.template $SPARK_FOLDER/conf/spark-env.sh
			echo "SPARK_MASTER_IP=$ip" >> $SPARK_FOLDER/conf/spark-env.sh
			echo "SPARK_WORKER_MEMORY=1g" >> $SPARK_FOLDER/conf/spark-env.sh
		fi
    done

    # 共有フォルダ内にSSHキーを生成
    if [[ ! -d $SYNCED_FOLDER/.ssh ]]; then
        mkdir $SYNCED_FOLDER/.ssh
        ssh-keygen -t rsa -f $SYNCED_FOLDER/.ssh/id_rsa -N ""
    fi

    # 共有フォルダからHOMEの.sshにSSHキーをコピー
    install -m 600 -o vagrant -g vagrant $SYNCED_FOLDER/.ssh/id_rsa $HOME/.ssh/

	# 改行を入れるために"echo"が必要
	# 公開鍵を登録
    (echo; cat $SYNCED_FOLDER/.ssh/id_rsa.pub) >> $HOME/.ssh/authorized_keys
    
	touch /etc/.provisioned
fi
