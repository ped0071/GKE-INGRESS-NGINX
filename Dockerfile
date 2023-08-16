FROM node:18-alpine

WORKDIR /app

COPY nodejs/ .

RUN npm i

EXPOSE 8080

CMD [ "npm", "run", "start" ]