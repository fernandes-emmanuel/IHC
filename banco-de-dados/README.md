# Banco de Dados — Módulo de Controle de Acessos

| Arquivo | Conteúdo |
|---|---|
| `Trabalho_BD_Seguranca_e_Permissoes.pdf` | Entrega: modelo conceitual, modelo físico e consultas SQL |
| `modelo-conceitual.png` | Imagem do modelo conceitual |
| `modelo-fisico.png` | Imagem do modelo físico |
| `sql/01_modelo_fisico.sql` | Criação das tabelas |
| `sql/02_dados_exemplo.sql` | Dados de exemplo |
| `sql/03_consultas.sql` | Consultas das interfaces |

```bash
psql -d controle_acesso -f sql/01_modelo_fisico.sql -f sql/02_dados_exemplo.sql -f sql/03_consultas.sql
```
