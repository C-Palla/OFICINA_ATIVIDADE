-- 05_indices.sql
-- Índices finais. Preencha nos comentários a redução real observada após rodar EXPLAIN ANALYZE.
-- Regra do documento: cada índice precisa ter plano antes e depois no relatório.

SET search_path TO oficina, public;

-- Q2: filtro por status/data de conclusão e junção com pagamento. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_agendamento_status_data_conclusao
ON agendamento (status, data_conclusao, id_agendamento);

-- Q2/Q5/Q6: pagamentos confirmados e junção por OS. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_pagamento_status_agendamento
ON pagamento (status_pagamento, id_agendamento);

-- Q3: agrupamento por tipo de serviço e junção com agendamento. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_item_servico_tipo_agendamento
ON item_servico (id_tipo_servico, id_agendamento);

-- Q4/Q8: ranking e avaliações por funcionário. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_item_servico_funcionario_agendamento
ON item_servico (id_funcionario, id_agendamento);

-- Q5: navegação cliente -> veículo -> agendamento. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_veiculo_cliente
ON veiculo (id_cliente, id_veiculo);

-- Q5: junção de agendamento por veículo. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_agendamento_veiculo
ON agendamento (id_veiculo, id_agendamento);

-- Q7: filtro de peças abaixo do estoque mínimo. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_peca_alerta_estoque
ON peca (quantidade_atual, quantidade_minima)
WHERE quantidade_atual < quantidade_minima;

-- Q8: avaliação por OS. Redução observada: preencher após EXPLAIN ANALYZE.
CREATE INDEX IF NOT EXISTS idx_avaliacao_agendamento
ON avaliacao (id_agendamento);

ANALYZE;
