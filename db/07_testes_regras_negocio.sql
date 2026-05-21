-- 07_testes_regras_negocio.sql
-- Testes negativos para provar regras de negócio obrigatórias.
-- Execute manualmente um bloco por vez; cada INSERT inválido deve gerar erro.

SET search_path TO oficina, public;

-- Deve falhar: cliente PF sem CPF.
INSERT INTO cliente (nome, email, tipo_pessoa, cpf, cnpj)
VALUES ('PF inválido', 'pf_invalido@email.com', 'PF', NULL, NULL);

-- Deve falhar: salário igual a zero.
INSERT INTO funcionario (nome, email, cargo, salario)
VALUES ('Funcionário inválido', 'func_invalido@oficina.com.br', 'Mecânico', 0);

-- Deve falhar: data de conclusão anterior à abertura.
INSERT INTO agendamento (id_veiculo, data_abertura, data_conclusao, status, km_entrada, km_saida)
VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Concluído', 1000, 1010);

-- Deve falhar: km de saída menor que km de entrada.
INSERT INTO agendamento (id_veiculo, data_abertura, data_conclusao, status, km_entrada, km_saida)
VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 hour', 'Concluído', 2000, 1500);

-- Deve falhar: estoque negativo.
UPDATE peca SET quantidade_atual = -1 WHERE id_peca = 1;

-- Deve falhar: nota fora de 1 a 5.
INSERT INTO avaliacao (id_agendamento, nota, comentario)
VALUES (1, 6, 'Nota inválida');

-- Deve falhar: pagamento em OS não concluída.
INSERT INTO pagamento (id_agendamento, forma_pagamento, status_pagamento, valor_pago)
SELECT id_agendamento, 'PIX', 'Confirmado', 100
FROM agendamento
WHERE status <> 'Concluído'
LIMIT 1;
