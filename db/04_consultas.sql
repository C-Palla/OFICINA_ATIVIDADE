-- 04_consultas.sql
-- Consultas analíticas exigidas na Entrega 4.

SET search_path TO oficina, public;

-- Q1. Contagem de registros por tabela.
SELECT 'cliente' AS tabela, COUNT(*) AS total FROM cliente
UNION ALL SELECT 'veiculo', COUNT(*) FROM veiculo
UNION ALL SELECT 'funcionario', COUNT(*) FROM funcionario
UNION ALL SELECT 'usuario_sistema', COUNT(*) FROM usuario_sistema
UNION ALL SELECT 'tipo_servico', COUNT(*) FROM tipo_servico
UNION ALL SELECT 'peca', COUNT(*) FROM peca
UNION ALL SELECT 'agendamento', COUNT(*) FROM agendamento
UNION ALL SELECT 'item_servico', COUNT(*) FROM item_servico
UNION ALL SELECT 'item_peca', COUNT(*) FROM item_peca
UNION ALL SELECT 'pagamento', COUNT(*) FROM pagamento
UNION ALL SELECT 'avaliacao', COUNT(*) FROM avaliacao
ORDER BY tabela;

-- Q2. Receita total e ticket médio por mês nos últimos 12 meses, apenas OS concluídas.
SELECT
  TO_CHAR(DATE_TRUNC('month', a.data_conclusao), 'YYYY-MM') AS mes,
  SUM(p.valor_pago) AS receita_total,
  ROUND(AVG(p.valor_pago), 2) AS ticket_medio,
  COUNT(DISTINCT a.id_agendamento) AS quantidade_os
FROM agendamento a
JOIN pagamento p ON p.id_agendamento = a.id_agendamento
WHERE a.status = 'Concluído'
  AND p.status_pagamento = 'Confirmado'
  AND a.data_conclusao >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', a.data_conclusao)
ORDER BY mes DESC;

-- Q3. Ranking dos 10 serviços mais realizados.
SELECT
  ts.descricao,
  COUNT(isv.id_item_servico) AS quantidade_execucoes,
  SUM(isv.total_item) AS faturamento_total
FROM tipo_servico ts
JOIN item_servico isv ON isv.id_tipo_servico = ts.id_tipo_servico
JOIN agendamento a ON a.id_agendamento = isv.id_agendamento
WHERE a.status = 'Concluído'
GROUP BY ts.id_tipo_servico, ts.descricao
ORDER BY quantidade_execucoes DESC, faturamento_total DESC
LIMIT 10;

-- Q4. Ranking de funcionários por faturamento em OS concluídas.
SELECT
  f.nome,
  f.cargo,
  COUNT(DISTINCT isv.id_agendamento) AS os_atendidas,
  SUM(isv.total_item) AS faturamento_gerado
FROM funcionario f
JOIN item_servico isv ON isv.id_funcionario = f.id_funcionario
JOIN agendamento a ON a.id_agendamento = isv.id_agendamento
WHERE a.status = 'Concluído'
GROUP BY f.id_funcionario, f.nome, f.cargo
ORDER BY faturamento_gerado DESC, os_atendidas DESC;

-- Q5. Top 20 clientes com maior gasto acumulado, distinguindo PF/PJ.
SELECT
  c.nome,
  c.tipo_pessoa,
  CASE WHEN c.tipo_pessoa = 'PF' THEN c.cpf ELSE c.cnpj END AS documento,
  SUM(p.valor_pago) AS gasto_total,
  COUNT(DISTINCT a.id_agendamento) AS quantidade_os
FROM cliente c
JOIN veiculo v ON v.id_cliente = c.id_cliente
JOIN agendamento a ON a.id_veiculo = v.id_veiculo
JOIN pagamento p ON p.id_agendamento = a.id_agendamento
WHERE a.status = 'Concluído'
  AND p.status_pagamento = 'Confirmado'
GROUP BY c.id_cliente, c.nome, c.tipo_pessoa, documento
ORDER BY gasto_total DESC
LIMIT 20;

-- Q6. Distribuição percentual das formas de pagamento confirmadas.
SELECT
  forma_pagamento,
  COUNT(*) AS qtd_transacoes,
  SUM(valor_pago) AS valor_total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_transacoes,
  ROUND(SUM(valor_pago) * 100.0 / SUM(SUM(valor_pago)) OVER (), 2) AS percentual_valor
FROM pagamento
WHERE status_pagamento = 'Confirmado'
GROUP BY forma_pagamento
ORDER BY valor_total DESC;

-- Q7. Peças com estoque abaixo do mínimo.
SELECT
  nome,
  fornecedor,
  quantidade_atual,
  quantidade_minima,
  quantidade_minima - quantidade_atual AS deficit,
  preco_unitario
FROM peca
WHERE quantidade_atual < quantidade_minima
ORDER BY deficit DESC, nome;

-- Q8. Nota média por funcionário com pelo menos cinco avaliações.
WITH avaliacoes_por_funcionario AS (
  SELECT DISTINCT
    f.id_funcionario,
    f.nome,
    av.id_avaliacao,
    av.nota
  FROM funcionario f
  JOIN item_servico isv ON isv.id_funcionario = f.id_funcionario
  JOIN agendamento a ON a.id_agendamento = isv.id_agendamento
  JOIN avaliacao av ON av.id_agendamento = a.id_agendamento
  WHERE a.status = 'Concluído'
)
SELECT
  nome,
  ROUND(AVG(nota), 2) AS nota_media,
  COUNT(id_avaliacao) AS total_avaliacoes
FROM avaliacoes_por_funcionario
GROUP BY id_funcionario, nome
HAVING COUNT(id_avaliacao) >= 5
ORDER BY nota_media DESC, total_avaliacoes DESC;
