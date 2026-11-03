# Banco de Dados — Módulo de Controle de Acessos (Segurança e Permissões)

Trabalho da disciplina de **Banco de Dados**. Não tem relação com o protótipo de IHC (`../autenticacao`).

| Arquivo | Conteúdo |
|---|---|
| `Trabalho_BD_Seguranca_e_Permissoes.pdf` | **Entrega**: domínio, modelo conceitual, modelo físico, dicionário de dados, restrições, consultas por interface com resultados e DDL |
| `modelo-conceitual.png` | Imagem do modelo conceitual (ER) |
| `modelo-fisico.png` | Imagem do modelo físico (tabelas, tipos, PK/FK) |
| `sql/01_modelo_fisico.sql` | DDL: tabelas, PK, FK, UNIQUE, CHECK, índices, triggers e comentários |
| `sql/02_dados_exemplo.sql` | Dados das telas do enunciado |
| `sql/03_consultas.sql` | Consultas C01–C24 de cada interface |
| `sql/04_testes_integridade.sql` | Testes que devem falhar, provando as restrições |

## Executar (PostgreSQL 16)

```bash
createdb controle_acesso
psql -d controle_acesso -f sql/01_modelo_fisico.sql
psql -d controle_acesso -f sql/02_dados_exemplo.sql
psql -d controle_acesso -f sql/03_consultas.sql
psql -d controle_acesso -f sql/04_testes_integridade.sql
```
