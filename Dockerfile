FROM adoptopenjdk/openjdk8:x86_64-ubantu-jdk8u212-b03
MAINTAINER acchan

ENV RUN_USER                                daemon
ENV RUN_GROUP                               daemon

ENV JIRA_HOME                               /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR                        /opt/atlassian/jira
ENV JIRA_LOG                                /opt/atlassian/jira/logs

VOLUME ["${JIRA_HOME}"]
VOLUME ["${JIRA_LOG}"]

EXPOSE 8080

WORKDIR $JIRA_HOME

EXPOSE 8080

CMD ["/entrypoint.sh", "-fg"]
ENTRYPOINT ["/tini", "--"]

RUN apt-get update && apt-get install -y wget unzip curl bash procps prel fontconfig && apt-get clean -y && apt-get autoremove -y
RUN apt-get update && install -y font-ipafont && apt-get clean -y && apt-get autoremove -y

ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY entrypoint.sh                          /entrypoint.sh

ARG JIRA_VERSION=7.13.3
ARG DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${JIRA_VERSION}.tar.gz

RUN mkdir -p                             ${JIRA_INSTALL_DIR} \
    && curl -L --silent                  ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${JIRA_INSTALL_DIR}/ \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${JIRA_HOME}/ \
    && chmod -R 755 /opt/atlassian/jira/logs \
    && sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/port="8080"/port="8080" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${JIRA_INSTALL_DIR}/conf/server.xml \
    && sed -i -e 's/JVM_SUPPORT_RECOMMENDED_ARGS=""/JVM_SUPPORT_RECOMMENDED_ARGS:="${JVM_SUPPORT_RECOMMENDED_ARGS}"/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e '/JVM_EXTRA_ARGS="-XX:-OmitStackTraceInFastThrow"/i JVM_EXTRA_ARGS="-XX:PrintGCDetails -XX:MetaspaceSize=512m -XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+TranceGen0Time -XX:TranceGen1Time"' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e '/1catalina.org.apache.juli.AsyncFileHandler.level = FINE/i 1catalina.org.apache.juli.AsyncFileHandler.suffix=log' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/1catalina.org.apache.juli.AsyncFileHandler.level = FINE/i 1catalina.org.apache.juli.AsyncFileHandler.rotatable=false' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/2localhost.org.apache.juli.AsyncFileHandler.level = FINE/i 2localhost.org.apache.juli.AsyncFileHandler.suffix=log' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/2localhost.org.apache.juli.AsyncFileHandler.level = FINE/i 2localhost.org.apache.juli.AsyncFileHandler.rotatable=false' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/3manager.org.apache.juli.AsyncFileHandler.level = FINE/i 3manager.org.apache.juli.AsyncFileHandler.suffix=log' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/3manager.org.apache.juli.AsyncFileHandler.level = FINE/i 3manager.org.apache.juli.AsyncFileHandler.rotatable=false' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/4host-manager.org.apache.juli.AsyncFileHandler.level = FINE/i 4host-manager.org.apache.juli.AsyncFileHandler.suffix=log' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e '/4host-manager.org.apache.juli.AsyncFileHandler.level = FINE/i 4host-manager.org.apache.juli.AsyncFileHandler.rotatable=false' ${JIRA_INSTALL_DIR}/conf/logging.properties \
    && sed -i -e 's/issue.field.issuetype.incompatible.types/#&/' ${JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/classes/com/atlassian/jira/web/action/JiraWebActionSupport.properties \
    && sed -i -e 's/<session-timeout>.*<\/session-timeout>/<session-timeout>1440<\/session-timeout>/' ${JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/web.xml

COPY log4j.properties                       ${JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/classes/log4j.properties
COPY server.xml                             ${JIRA_INSTALL_DIR}/conf/server.xml

VOLUME ["${JIRA_INSTALL_DIR}"]

RUN chown -R ${RUN_USER}:${RUN_GROUP} ${JIRA_INSTALL_DIR}/atlassian-jira/WEB-INF/classes/log4j.properties\ 
 && chown -R ${RUN_USER}:${RUN_GROUP} ${JIRA_INSTALL_DIR}/conf/server.xml 
