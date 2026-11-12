FROM maven:3.9.6-eclipse-temurin-17 AS build_image
RUN apt update && apt install git -y
RUN git clone https://github.com/devopshydclub/vprofile-project.git
RUN cd vprofile-project && git checkout docker

RUN sed -i 's/vpromq01/rabbitmq/g' vprofile-project/src/main/resources/application.properties && \
    sed -i 's/vprodb/mariadb/g' vprofile-project/src/main/resources/application.properties && \
    sed -i 's/vprocache01/memcached/g' vprofile-project/src/main/resources/application.properties && \
    sed -i 's/15672/5672/g' vprofile-project/src/main/resources/application.properties
    
RUN cd vprofile-project && mvn install

FROM tomcat:9-jre11
LABEL "Project"="Vprofile"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build_image vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]