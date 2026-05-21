-- 03_dados.sql
-- Carga representativa para PostgreSQL 16+
-- Volumes mínimos exigidos no documento oficial.

SET search_path TO oficina, public;

INSERT INTO funcionario (nome, email, cargo, especialidade, salario)
SELECT
  'Funcionário ' || i,
  'funcionario' || i || '@oficina.com.br',
  CASE
    WHEN i % 5 = 0 THEN 'Gerente'
    WHEN i % 5 = 1 THEN 'Atendente'
    WHEN i % 5 = 2 THEN 'Mecânico'
    WHEN i % 5 = 3 THEN 'Eletricista'
    ELSE 'Consultor técnico'
  END,
  CASE
    WHEN i % 4 = 0 THEN 'Motor'
    WHEN i % 4 = 1 THEN 'Freios'
    WHEN i % 4 = 2 THEN 'Suspensão'
    ELSE 'Ar-condicionado'
  END,
  ROUND((2500 + random() * 6000)::numeric, 2)
FROM generate_series(1, 55) AS s(i);

INSERT INTO usuario_sistema (id_funcionario, login, senha_hash, perfil)
SELECT
  id_funcionario,
  'usuario' || id_funcionario,
  '$2a$10$hash_demonstrativo_para_trabalho_academico',
  CASE WHEN cargo = 'Gerente' THEN 'Gerente' ELSE 'Atendente' END
FROM funcionario
WHERE id_funcionario <= 20;

INSERT INTO tipo_servico (descricao, preco_base, tempo_estimado_minutos)
SELECT
  'Serviço ' || i || ' - ' || CASE
    WHEN i % 5 = 0 THEN 'Troca de óleo'
    WHEN i % 5 = 1 THEN 'Revisão de freios'
    WHEN i % 5 = 2 THEN 'Alinhamento e balanceamento'
    WHEN i % 5 = 3 THEN 'Diagnóstico elétrico'
    ELSE 'Manutenção de ar-condicionado'
  END,
  ROUND((80 + random() * 920)::numeric, 2),
  30 + (i * 10)
FROM generate_series(1, 25) AS s(i);

INSERT INTO peca (nome, fornecedor, quantidade_atual, quantidade_minima, preco_unitario)
SELECT
  'Peça ' || i,
  'Fornecedor ' || ((i % 8) + 1),
  CASE WHEN i % 6 = 0 THEN 3 ELSE (10 + (random() * 90)::int) END,
  CASE WHEN i % 6 = 0 THEN 12 ELSE 8 END,
  ROUND((20 + random() * 680)::numeric, 2)
FROM generate_series(1, 45) AS s(i);

INSERT INTO cliente (nome, email, telefone, tipo_pessoa, cpf, cnpj)
SELECT
  CASE WHEN i % 2 = 0 THEN 'Cliente PF ' || i ELSE 'Empresa Cliente ' || i END,
  'cliente' || i || '@email.com',
  '849' || LPAD(i::text, 8, '0'),
  CASE WHEN i % 2 = 0 THEN 'PF' ELSE 'PJ' END,
  CASE WHEN i % 2 = 0 THEN LPAD(i::text, 11, '0')::char(11) ELSE NULL END,
  CASE WHEN i % 2 <> 0 THEN LPAD(i::text, 14, '0')::char(14) ELSE NULL END
FROM generate_series(1, 210) AS s(i);

INSERT INTO veiculo (id_cliente, placa, marca, modelo, ano_fabricacao, cor)
SELECT
  1 + ((i - 1) % 210),
  ('ABC' || ((i % 10)::text) || CHR(65 + (i % 26)) || LPAD((i % 100)::text, 2, '0'))::varchar(7),
  'Marca ' || ((i % 12) + 1),
  'Modelo ' || ((i % 30) + 1),
  2010 + (i % 16),
  CASE WHEN i % 5 = 0 THEN 'Preto' WHEN i % 5 = 1 THEN 'Branco' WHEN i % 5 = 2 THEN 'Prata' WHEN i % 5 = 3 THEN 'Vermelho' ELSE 'Azul' END
FROM generate_series(1, 520) AS s(i);

INSERT INTO agendamento (id_veiculo, data_abertura, data_conclusao, status, km_entrada, km_saida, observacoes)
SELECT
  1 + ((i - 1) % 520),
  (CURRENT_DATE - ((i % 540) || ' days')::interval + ((i % 10) || ' hours')::interval),
  CASE WHEN i <= 3200 THEN (CURRENT_DATE - ((i % 540) || ' days')::interval + ((i % 10) || ' hours')::interval + INTERVAL '2 hours') ELSE NULL END,
  CASE
    WHEN i <= 3200 THEN 'Concluído'
    WHEN i <= 3300 THEN 'Em andamento'
    WHEN i <= 3400 THEN 'Cancelado'
    WHEN i <= 3500 THEN 'No-show'
    ELSE 'Agendado'
  END,
  10000 + (i * 7),
  CASE WHEN i <= 3200 THEN 10000 + (i * 7) + 20 + (i % 120) ELSE NULL END,
  'Carga automática coerente para a atividade.'
FROM generate_series(1, 3600) AS s(i);

WITH dados AS (
  SELECT
    1 + ((i - 1) % 3600) AS id_agendamento,
    1 + ((i - 1) % 25) AS id_tipo_servico,
    1 + ((i - 1) % 55) AS id_funcionario,
    1 + (i % 2) AS quantidade,
    CASE WHEN i % 10 = 0 THEN 5 ELSE 0 END AS desconto_percentual
  FROM generate_series(1, 7200) AS s(i)
)
INSERT INTO item_servico (id_agendamento, id_tipo_servico, id_funcionario, quantidade, preco_unitario, desconto_percentual)
SELECT
  d.id_agendamento,
  d.id_tipo_servico,
  d.id_funcionario,
  d.quantidade,
  ts.preco_base,
  d.desconto_percentual
FROM dados d
JOIN tipo_servico ts ON ts.id_tipo_servico = d.id_tipo_servico;

WITH dados AS (
  SELECT
    1 + ((i - 1) % 3600) AS id_agendamento,
    1 + ((i - 1) % 45) AS id_peca,
    1 + (i % 3) AS quantidade,
    CASE WHEN i % 12 = 0 THEN 3 ELSE 0 END AS desconto_percentual
  FROM generate_series(1, 5100) AS s(i)
)
INSERT INTO item_peca (id_agendamento, id_peca, quantidade, preco_unitario, desconto_percentual)
SELECT
  d.id_agendamento,
  d.id_peca,
  d.quantidade,
  p.preco_unitario,
  d.desconto_percentual
FROM dados d
JOIN peca p ON p.id_peca = d.id_peca;

INSERT INTO pagamento (id_agendamento, forma_pagamento, status_pagamento, valor_pago, data_pagamento, parcelas)
SELECT
  id_agendamento,
  CASE
    WHEN id_agendamento % 6 = 0 THEN 'PIX'
    WHEN id_agendamento % 6 = 1 THEN 'Dinheiro'
    WHEN id_agendamento % 6 = 2 THEN 'Cartão de crédito'
    WHEN id_agendamento % 6 = 3 THEN 'Cartão de débito'
    WHEN id_agendamento % 6 = 4 THEN 'Boleto'
    ELSE 'Transferência'
  END,
  'Confirmado',
  GREATEST(valor_total, 1),
  data_conclusao + INTERVAL '30 minutes',
  CASE WHEN id_agendamento % 4 = 0 THEN 3 ELSE 1 END
FROM agendamento
WHERE status = 'Concluído'
ORDER BY id_agendamento
LIMIT 3000;

INSERT INTO avaliacao (id_agendamento, nota, comentario, data_avaliacao)
SELECT
  id_agendamento,
  1 + (id_agendamento % 5),
  CASE
    WHEN id_agendamento % 5 = 0 THEN 'Atendimento excelente.'
    WHEN id_agendamento % 5 = 1 THEN 'Bom atendimento.'
    WHEN id_agendamento % 5 = 2 THEN 'Serviço dentro do esperado.'
    WHEN id_agendamento % 5 = 3 THEN 'Poderia ser mais rápido.'
    ELSE 'Cliente satisfeito com ressalvas.'
  END,
  data_conclusao + INTERVAL '1 day'
FROM agendamento
WHERE status = 'Concluído'
ORDER BY id_agendamento
LIMIT 2200;

ANALYZE;
