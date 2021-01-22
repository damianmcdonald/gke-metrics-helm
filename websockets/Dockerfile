FROM node:14

ADD run.sh /run.sh

RUN npm install ws && npm install os && chmod +x run.sh

CMD ["/run.sh"]

EXPOSE 8010