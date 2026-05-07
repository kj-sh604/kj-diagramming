FROM ubuntu:22.04

WORKDIR /srv/www

RUN apt-get update \
	&& apt-get install -y --no-install-recommends python3 \
	&& rm -rf /var/lib/apt/lists/*

COPY ./excalidraw-app/build/ /srv/www/

EXPOSE 8000

CMD ["python3", "-m", "http.server", "8000"]