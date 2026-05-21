# Sistema de Agendamento de Manutenção Veicular — Banco de Dados II

Este repositório foi reorganizado para seguir o documento **atividade_bd_oficina_v4 (Oficial)**.

## Estrutura

```text
db/
  01_modelo_logico.puml
  02_ddl.sql
  03_dados.sql
  04_consultas.sql
  05_indices.sql
  06_explain_analyze_modelo.sql
  07_testes_regras_negocio.sql

docs/
  relatorio_explain_analyze_modelo.md
```

## O que foi corrigido em relação ao banco anterior

- Separação dos arquivos por entrega.
- Troca de comandos misturados de SQLite por SQL compatível com PostgreSQL 16+.
- Criação de `schema oficina`.
- Criação de domínios com `CREATE DOMAIN`.
- Criação da entidade `usuario_sistema`, separada das entidades de negócio, para autenticação futura via JWT.
- Uso de `NUMERIC`, não `FLOAT`, para valores financeiros.
- Criação de colunas `GENERATED ALWAYS AS ... STORED` para totais de itens e valor total da OS.
- Triggers para recalcular automaticamente os totais da ordem de serviço.
- Triggers para impedir pagamento e avaliação em OS que não esteja com status `Concluído`.
- Carga de dados com volume acima do mínimo exigido.
- Oito consultas analíticas exigidas.
- Arquivo separado de índices.
- Modelo de relatório para o ciclo `EXPLAIN ANALYZE`.

## Como executar no PostgreSQL

Crie um banco vazio. Exemplo:

```bash
createdb oficina_bd
```

Execute os scripts nesta ordem:

```bash
psql -d oficina_bd -f db/02_ddl.sql
psql -d oficina_bd -f db/03_dados.sql
psql -d oficina_bd -f db/04_consultas.sql
```

Para a entrega de otimização:

```bash
psql -d oficina_bd -f db/06_explain_analyze_modelo.sql
psql -d oficina_bd -f db/05_indices.sql
psql -d oficina_bd -f db/06_explain_analyze_modelo.sql
```

Depois, copie os resultados para `docs/relatorio_explain_analyze_modelo.md`.

## Volumes da carga de dados

| Tabela | Registros gerados | Mínimo exigido |
|---|---:|---:|
| cliente | 210 | 200 |
| veiculo | 520 | 500 |
| funcionario | 55 | 50 |
| tipo_servico | 25 | 20 |
| peca | 45 | 40 |
| agendamento | 3600 | 3500 |
| item_servico | 7200 | 7000 |
| item_peca | 5100 | 5000 |
| pagamento | 3000 | 3000 |
| avaliacao | 2200 | 2200 |

## Observação importante

O documento oficial pede PostgreSQL 16+. Por isso, o banco foi refeito em PostgreSQL e não em SQLite. O arquivo antigo `db.sqlite` não foi mantido como principal porque não atende a recursos obrigatórios do enunciado, como `CREATE DOMAIN`, `GENERATED ALWAYS AS ... STORED` no padrão usado, `EXPLAIN (ANALYZE, BUFFERS)` e organização por schema.

## Próximos passos para completar a entrega 6

O banco já está pronto para ser usado por um backend em Spring Boot, FastAPI ou Django REST Framework. Para finalizar a parte de aplicação, ainda será necessário criar:

- Backend com endpoints REST.
- Autenticação JWT com perfis `Atendente` e `Gerente`.
- Swagger/OpenAPI.
- Frontend funcional com login, dashboard, clientes, OS e estoque.


## Banco SQLite pronto

Também foi incluído o arquivo `db/db.sqlite`, já com as tabelas criadas e dados de exemplo inseridos. Ele serve para abrir rapidamente no DB Browser for SQLite ou em ferramentas semelhantes. A entrega oficial do enunciado continua sendo PostgreSQL, nos arquivos `02_ddl.sql` e `03_dados.sql`.
