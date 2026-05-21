# Relatório da Entrega 5 — EXPLAIN ANALYZE

> Preencha este relatório com as saídas reais do PostgreSQL. O documento oficial exige plano antes e depois de cada índice.

## Procedimento usado

1. Executar `db/02_ddl.sql`.
2. Executar `db/03_dados.sql`.
3. Executar `ANALYZE;`.
4. Executar `db/06_explain_analyze_modelo.sql` sem índices adicionais.
5. Anotar o menor tempo de pelo menos 3 execuções.
6. Executar `db/05_indices.sql`.
7. Executar novamente `db/06_explain_analyze_modelo.sql`.
8. Comparar tempo total, tipo de varredura, linhas lidas e buffers.

---

## Consulta 1 — Contagem de registros por tabela

### SQL executado

```sql
-- Colar aqui a Q1 do arquivo 04_consultas.sql
```

### Plano sem índice

```text
-- Colar aqui a saída completa do EXPLAIN ANALYZE antes dos índices.
```

### Diagnóstico

A consulta faz contagem completa das tabelas. Em geral, `Seq Scan` pode ser adequado porque a consulta precisa contar todos os registros.

### Decisão sobre índice

Não criar índice específico apenas para contagem total, pois a varredura completa costuma ser esperada.

### Plano com índice

```text
-- Colar aqui a saída após criação dos índices, se aplicável.
```

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 2 — Receita total e ticket médio por mês

### Diagnóstico esperado

A consulta filtra `agendamento.status`, `agendamento.data_conclusao`, `pagamento.status_pagamento` e junta por `id_agendamento`. Candidatos: `idx_agendamento_status_data_conclusao` e `idx_pagamento_status_agendamento`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 3 — Ranking dos 10 serviços mais realizados

### Diagnóstico esperado

A consulta agrupa `item_servico` por `id_tipo_servico` e filtra OS concluída por `agendamento.status`. Candidato: `idx_item_servico_tipo_agendamento`, além do índice de status/data em `agendamento`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 4 — Ranking de funcionários por faturamento

### Diagnóstico esperado

A consulta junta `funcionario`, `item_servico` e `agendamento`, agrupando por funcionário. Candidato: `idx_item_servico_funcionario_agendamento`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 5 — Top 20 clientes com maior gasto

### Diagnóstico esperado

A consulta percorre cliente → veículo → agendamento → pagamento. Candidatos: `idx_veiculo_cliente`, `idx_agendamento_veiculo` e `idx_pagamento_status_agendamento`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 6 — Distribuição das formas de pagamento

### Diagnóstico esperado

A consulta filtra pagamentos confirmados e agrupa por forma de pagamento. Candidato: `idx_pagamento_status_agendamento`. Dependendo da seletividade, o otimizador pode manter `Seq Scan`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 7 — Peças abaixo do estoque mínimo

### Diagnóstico esperado

A consulta filtra `quantidade_atual < quantidade_minima`. Candidato: índice parcial `idx_peca_alerta_estoque`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Consulta 8 — Nota média por funcionário

### Diagnóstico esperado

A consulta junta avaliações, OS concluídas e serviços por funcionário. Candidatos: `idx_item_servico_funcionario_agendamento`, `idx_avaliacao_agendamento` e índice de status em `agendamento`.

| Métrica | Sem índice | Com índice | Redução (%) |
|---|---:|---:|---:|
| Tempo total (ms) | preencher | preencher | preencher |
| Tipo de varredura | preencher | preencher | preencher |
| Linhas lidas | preencher | preencher | preencher |
| Buffers read | preencher | preencher | preencher |

---

## Síntese dos índices criados

| Índice | Tabela | Coluna(s) | Consulta que motivou | Redução de tempo |
|---|---|---|---|---|
| idx_agendamento_status_data_conclusao | agendamento | status, data_conclusao, id_agendamento | Q2, Q3, Q4, Q5, Q8 | preencher |
| idx_pagamento_status_agendamento | pagamento | status_pagamento, id_agendamento | Q2, Q5, Q6 | preencher |
| idx_item_servico_tipo_agendamento | item_servico | id_tipo_servico, id_agendamento | Q3 | preencher |
| idx_item_servico_funcionario_agendamento | item_servico | id_funcionario, id_agendamento | Q4, Q8 | preencher |
| idx_veiculo_cliente | veiculo | id_cliente, id_veiculo | Q5 | preencher |
| idx_agendamento_veiculo | agendamento | id_veiculo, id_agendamento | Q5 | preencher |
| idx_peca_alerta_estoque | peca | quantidade_atual, quantidade_minima | Q7 | preencher |
| idx_avaliacao_agendamento | avaliacao | id_agendamento | Q8 | preencher |
