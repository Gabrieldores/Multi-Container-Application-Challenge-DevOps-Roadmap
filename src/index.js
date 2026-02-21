require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

//Routes
const todoRoutes = require('./routes/todos');
app.use('/api/todos', todoRoutes);

app.get('/', (req, res) => {
    res.send("API de Tarefas está funcionando!")
})

//Conexão com o MongoDB
mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log("Conectado ao MongoDB")
        app.listen(PORT, () => {
            console.log(`Servidor rodando na porta ${PORT}`)
        })
    })
    .catch((err) => {
        console.error("Erro ao conectar ao MongoDB", err)
    })