const Todo = require("./models/Todo");

exports.getAllTodos = async (req, res) => {
    try {
        const todos = await Todo.find().sort({ createdAt: - 1 });
        res.json({ success: true, count: todos.length, data: todos });
    } catch (err) {
        res.status(500).json({ success: false, error: "Erro ao buscar tarefas" })
    }
}

exports.createTodo = async (req, res) => {
    try {
        const todo = await Todo.create(req.body);
        res.status(201).json({ success: true, data: todo });
    } catch (err) {
        res.status(500).json({ success: false, error: "Erro ao criar tarefa" })
    }
}

exports.getTodoById = async (req, res) => {
    try {
        const todo = await Todo.findById(req.params.id);
        if (!todo) {
            return res.status(404).json({ success: false, error: "Tarefa não encontrada" })
        }
        res.status(200).json({ success: true, data: todo });
    } catch (err) {
        res.status(500).json({ success: false, error: "Erro ao buscar tarefa" })
    }
}

exports.updateTodo = async (req, res) => {
    try {
        const todo = await Todo.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
        if (!todo) {
            return res.status(404).json({ success: false, error: "Tarefa não encontrada" })
        }
        res.status(200).json({ success: true, data: todo });
    } catch (err) {
        res.status(500).json({ success: false, error: "Erro ao atualizar tarefa" })
    }
}

exports.deleteTodo = async (req, res) => {
    try {
        const todo = await Todo.findByIdAndDelete(req.params.id);
        if (!todo) {
            return res.status(404).json({ success: false, error: "Tarefa não encontrada" })
        }
        res.status(200).json({ success: true, data: {} });
    } catch (err) {
        res.status(500).json({ success: false, error: "Erro ao deletar tarefa" })
    }
}