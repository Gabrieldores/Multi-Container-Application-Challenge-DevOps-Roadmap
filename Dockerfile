#Stage 1 - Development
FROM node:20-alpine AS development

WORKDIR /app

COPY package*.json .
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]

#Stage 2 - Production
FROM node:20-alpine AS production

WORKDIR /app

COPY package*.json .
RUN npm install --omit=dev

COPY . .

EXPOSE 3000

CMD ["npm", "start"]