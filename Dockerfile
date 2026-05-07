FROM busybox:stable

WORKDIR /srv/www

COPY ./excalidraw-app/build/ /srv/www/

EXPOSE 8000

CMD ["httpd", "-f", "-v", "-p", "8000", "-h", "/srv/www"]