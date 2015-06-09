FROM ubuntu:14.04
MAINTAINER Predrag Knezevic <pedjak@gmail.com>

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV JDK7_URL http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.tar.gz
ENV JDK8_URL http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz

COPY locale /etc/default/locale

#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -qq update
RUN apt-get install -y build-essential python-software-properties software-properties-common wget curl git fontconfig docker.io unzip

# SSH server
RUN apt-get install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN mkdir -p /opt/jdk
RUN mkdir -p /tmp/download

# Java 1.7
RUN cd /tmp/download && wget --header "Cookie: oraclelicense=accept-securebackup-cookie" $JDK7_URL && \
	tar -zxf `ls -1 *.tar.gz` -C /opt/jdk && \
	rm * -rf

# Java 1.8
RUN cd /tmp/download &&	 wget --header "Cookie: oraclelicense=accept-securebackup-cookie" $JDK8_URL && \
	tar -zxf `ls -1 *.tar.gz` -C /opt/jdk && \
	rm * -rf

# Set Java and Maven env variables
RUN echo "JDK7_HOME=\"`find /opt/jdk -name jdk1.7*`\"" >> /etc/environment
RUN echo "JAVA_HOME=\"`find /opt/jdk -name jdk1.7*`\"" >> /etc/environment
RUN echo "JDK8_HOME=\"`find /opt/jdk -name jdk1.8*`\"" >> /etc/environment

# Maven 3.0.5
RUN cd /tmp/download &&	wget http://apache.petsads.us/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz && \
	mkdir -p /opt/maven && \
	tar -zxf apache-maven-3.0.5-bin.tar.gz -C /opt/maven && \
	ln -s /opt/maven/apache-maven-3.0.5/bin/mvn /usr/bin && \
	rm * -rf

#Groovy 2.4
RUN cd /tmp/download && wget http://dl.bintray.com/groovy/maven/groovy-binary-2.4.3.zip && \
	unzip -d /opt groovy-binary-2.4.3.zip && \
	ln -s /opt/groovy-2.4.3/bin/groovy /usr/bin && \
	rm * -rf

# Set the default java version to 1.7
RUN update-alternatives --install /usr/bin/java java `find /opt/jdk -name jdk1.7*`/bin/java 100
RUN update-alternatives --install /usr/bin/javac javac `find /opt/jdk -name jdk1.7*`/bin/javac 100

ENV M2_HOME /opt/maven/apache-maven-3.0.5
#ENV JAVA_OPTS -Xmx2G -Xms2G -XX:PermSize=256M -XX:MaxPermSize=256m

# Load scripts
COPY bootstrap bootstrap
RUN chmod +x -Rv bootstrap

USER root

# Add user jenkins to the image
RUN adduser --quiet jenkins
RUN adduser jenkins sudo
RUN echo "jenkins:jenkins" | chpasswd

# Adjust perms for jenkins user
#RUN chown -R jenkins /opt/nvm
RUN echo "JDK7_HOME=\"`find /opt/jdk -name jdk1.7*`\"" >> /etc/environment
RUN echo "JDK8_HOME=\"`find /opt/jdk -name jdk1.8*`\"" >> /etc/environment
#RUN echo "source /opt/nvm/nvm.sh" >> /home/jenkins/.profile
RUN chown jenkins /home/jenkins/.profile

# Standard SSH port
EXPOSE 22
RUN sed -i 's|PermitRootLogin without-password|PermitRootLogin yes|g' /etc/ssh/sshd_config

#NFS
RUN apt-get install -y nfs-common portmap

RUN apt-get install -y parallel

# cleanup
RUN rm -rf /tmp/download && rm -rf /var/lib/apt/lists/* 

# Startup services when running the container
CMD ["./bootstrap/init.sh"]
