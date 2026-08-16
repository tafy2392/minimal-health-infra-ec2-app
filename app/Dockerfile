FROM node:24-alpine

WORKDIR /app

COPY package.json ./

COPY index.js ./

ENV NODE_ENV=production \
    PORT=3000

EXPOSE 3000

USER node

CMD ["node", "index.js"]
