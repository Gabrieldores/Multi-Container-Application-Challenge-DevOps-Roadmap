
```markdown
# Multi-container Service

Este projeto foi desenvolvido como parte do desafio [Multi-container Service](https://roadmap.sh/projects/multi-container-service) do [roadmap.sh](https://roadmap.sh). O objetivo é demonstrar a orquestração de múltiplos serviços utilizando Docker e Docker Compose.

### Tecnologias Utilizadas

- **Docker**: Containerização da aplicação.
- **Docker Compose**: Orquestração de múltiplos containers.
- **Nginx**: Atuando como Proxy Reverso.
- **Backend**: [Inserir Tecnologia, ex: Node.js/Python]
- **Banco de Dados**: [Inserir Tecnologia, ex: PostgreSQL/Redis]

## Arquitetura

A aplicação é composta pelos seguintes serviços:

1.  **Reverse Proxy (Nginx)**: Porta de entrada que encaminha as requisições para o backend.
2.  **App Service**: A lógica da aplicação/API.
3.  **Database**: Persistência de dados.

## Como Executar

Certifique-se de ter o [Docker](https://www.docker.com/) instalado em sua máquina.

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/multi-container-service.git
   cd multi-container-service
   ```

1. Inicie os serviços com o Docker Compose:

   ```bash
   docker-compose up --build
   ```

2. Acesse a aplicação em: `http://localhost`

## 🔗 Links Relacionados

- [Desafio Original - Roadmap.sh](https://roadmap.sh/projects/multi-container-service)

```
