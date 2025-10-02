FROM alpine:3.22 as downloader

ARG rport_version=0.9.14
#ARG frontend_build=0.9.12-17-build-1145
ARG NOVNC_VERSION=1.3.0

RUN apk add unzip

WORKDIR /app/

RUN wget -q https://github.com/openrport/openrport/releases/download/${rport_version}/rportd_${rport_version}_Linux_x86_64.tar.gz -O rportd.tar.gz \
     && tar xzf rportd.tar.gz rportd
RUN wget -q https://github.com/openrport/openrport-ui/releases/download/alpha-2025-09-15-0949/openrport-ui-alpha-2025-09-15-0949.zip -O frontend.zip \
    && unzip frontend.zip -d ./frontend
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.zip -O novnc.zip \
    && unzip novnc.zip && mv noVNC-${NOVNC_VERSION} ./novnc

FROM alpine:latest

USER root

ARG TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN apk add --no-cache gcompat wget supervisor guacamole-server shadow
    
RUN apk --purge del apk-tools && rm -rf /tmp/* /var/tmp/*


COPY --from=downloader /app/rportd /usr/local/bin/rportd
COPY --from=downloader /app/frontend/ /var/www/html/
COPY --from=downloader /app/novnc/ /var/lib/rport-novnc
COPY supervisord.conf /etc/supervisord.conf

RUN useradd -d /var/lib/rport -m -U -r -s /bin/false rport

RUN chown -R rport:rport /var/www/html/

RUN touch /var/lib/rport/rport.log && chown rport /var/lib/rport/rport.log && touch /var/lib/rport/supervisord.log && chown rport /var/lib/rport/supervisord.log

USER rport

RUN chmod 755 -R /var/lib/rport/
EXPOSE 8080
EXPOSE 3000
EXPOSE 20000-30000
EXPOSE 4822

CMD ["/usr/bin/supervisord"]
