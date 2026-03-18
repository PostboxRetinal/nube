FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install --no-install-recommends -y apache2 apache2-utils 
RUN apt clean

EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]