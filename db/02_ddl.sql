-- 02_ddl.sql
-- Modelo físico PostgreSQL 16+ - Sistema de Agendamento de Manutenção Veicular
-- Execute este arquivo antes do 03_dados.sql.

DROP SCHEMA IF EXISTS oficina CASCADE;
CREATE SCHEMA oficina;
SET search_path TO oficina, public;

-- =========================
-- DOMÍNIOS RECORRENTES
-- =========================
CREATE DOMAIN dm_email AS VARCHAR(254)
  CHECK (VALUE ~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$');

CREATE DOMAIN dm_cpf AS CHAR(11)
  CHECK (VALUE ~ '^[0-9]{11}$');

CREATE DOMAIN dm_cnpj AS CHAR(14)
  CHECK (VALUE ~ '^[0-9]{14}$');

CREATE DOMAIN dm_telefone AS VARCHAR(20)
  CHECK (VALUE IS NULL OR VALUE ~ '^[0-9()+ \-]{8,20}$');

CREATE DOMAIN dm_placa AS VARCHAR(7)
  CHECK (VALUE ~ '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');

CREATE DOMAIN dm_dinheiro AS NUMERIC(12,2)
  CHECK (VALUE >= 0);

CREATE DOMAIN dm_percentual AS NUMERIC(5,2)
  CHECK (VALUE BETWEEN 0 AND 100);

CREATE DOMAIN dm_tipo_pessoa AS CHAR(2)
  CHECK (VALUE IN ('PF', 'PJ'));

CREATE DOMAIN dm_status_os AS VARCHAR(20)
  CHECK (VALUE IN ('Agendado', 'Em andamento', 'Concluído', 'Cancelado', 'No-show'));

CREATE DOMAIN dm_forma_pagamento AS VARCHAR(30)
  CHECK (VALUE IN ('PIX', 'Dinheiro', 'Cartão de crédito', 'Cartão de débito', 'Boleto', 'Transferência'));

CREATE DOMAIN dm_status_pagamento AS VARCHAR(20)
  CHECK (VALUE IN ('Pendente', 'Confirmado', 'Cancelado'));

CREATE DOMAIN dm_perfil_usuario AS VARCHAR(20)
  CHECK (VALUE IN ('Atendente', 'Gerente'));

-- =========================
-- TABELAS PRINCIPAIS
-- =========================
CREATE TABLE cliente (
  id_cliente BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  email dm_email NOT NULL UNIQUE,
  telefone dm_telefone,
  tipo_pessoa dm_tipo_pessoa NOT NULL,
  cpf dm_cpf UNIQUE,
  cnpj dm_cnpj UNIQUE,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_cliente_documento_valido CHECK (
    (tipo_pessoa = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL) OR
    (tipo_pessoa = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
  )
);

CREATE TABLE veiculo (
  id_veiculo BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
  placa dm_placa NOT NULL UNIQUE,
  marca VARCHAR(60) NOT NULL,
  modelo VARCHAR(60) NOT NULL,
  ano_fabricacao INTEGER NOT NULL CHECK (ano_fabricacao BETWEEN 1950 AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER + 1),
  cor VARCHAR(30)
);

CREATE TABLE funcionario (
  id_funcionario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  email dm_email NOT NULL UNIQUE,
  cargo VARCHAR(60) NOT NULL,
  especialidade VARCHAR(80),
  salario dm_dinheiro NOT NULL CHECK (salario > 0),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario_sistema (
  id_usuario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_funcionario BIGINT NOT NULL UNIQUE REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
  login VARCHAR(80) NOT NULL UNIQUE,
  senha_hash TEXT NOT NULL,
  perfil dm_perfil_usuario NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tipo_servico (
  id_tipo_servico BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  descricao VARCHAR(120) NOT NULL UNIQUE,
  preco_base dm_dinheiro NOT NULL,
  tempo_estimado_minutos INTEGER NOT NULL CHECK (tempo_estimado_minutos > 0),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE peca (
  id_peca BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  fornecedor VARCHAR(120) NOT NULL,
  quantidade_atual INTEGER NOT NULL DEFAULT 0 CHECK (quantidade_atual >= 0),
  quantidade_minima INTEGER NOT NULL DEFAULT 0 CHECK (quantidade_minima >= 0),
  preco_unitario dm_dinheiro NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE agendamento (
  id_agendamento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_veiculo BIGINT NOT NULL REFERENCES veiculo(id_veiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
  data_abertura TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_conclusao TIMESTAMPTZ,
  status dm_status_os NOT NULL DEFAULT 'Agendado',
  km_entrada INTEGER NOT NULL CHECK (km_entrada >= 0),
  km_saida INTEGER,
  total_mao_de_obra dm_dinheiro NOT NULL DEFAULT 0,
  total_pecas dm_dinheiro NOT NULL DEFAULT 0,
  valor_total dm_dinheiro GENERATED ALWAYS AS (total_mao_de_obra + total_pecas) STORED,
  observacoes TEXT,
  CONSTRAINT ck_agendamento_datas CHECK (data_conclusao IS NULL OR data_conclusao >= data_abertura),
  CONSTRAINT ck_agendamento_km CHECK (km_saida IS NULL OR km_saida >= km_entrada),
  CONSTRAINT ck_agendamento_status_conclusao CHECK (
    (status = 'Concluído' AND data_conclusao IS NOT NULL) OR
    (status <> 'Concluído')
  )
);

CREATE TABLE item_servico (
  id_item_servico BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_agendamento BIGINT NOT NULL REFERENCES agendamento(id_agendamento) ON UPDATE CASCADE ON DELETE CASCADE,
  id_tipo_servico BIGINT NOT NULL REFERENCES tipo_servico(id_tipo_servico) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_funcionario BIGINT NOT NULL REFERENCES funcionario(id_funcionario) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantidade INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
  preco_unitario dm_dinheiro NOT NULL,
  desconto_percentual dm_percentual NOT NULL DEFAULT 0,
  total_item dm_dinheiro GENERATED ALWAYS AS (
    ROUND((quantidade * preco_unitario) * (1 - desconto_percentual / 100), 2)
  ) STORED
);

CREATE TABLE item_peca (
  id_item_peca BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_agendamento BIGINT NOT NULL REFERENCES agendamento(id_agendamento) ON UPDATE CASCADE ON DELETE CASCADE,
  id_peca BIGINT NOT NULL REFERENCES peca(id_peca) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantidade INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unitario dm_dinheiro NOT NULL,
  desconto_percentual dm_percentual NOT NULL DEFAULT 0,
  total_item dm_dinheiro GENERATED ALWAYS AS (
    ROUND((quantidade * preco_unitario) * (1 - desconto_percentual / 100), 2)
  ) STORED
);

CREATE TABLE pagamento (
  id_pagamento BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_agendamento BIGINT NOT NULL REFERENCES agendamento(id_agendamento) ON UPDATE CASCADE ON DELETE RESTRICT,
  forma_pagamento dm_forma_pagamento NOT NULL,
  status_pagamento dm_status_pagamento NOT NULL DEFAULT 'Confirmado',
  valor_pago dm_dinheiro NOT NULL CHECK (valor_pago > 0),
  data_pagamento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  parcelas INTEGER NOT NULL DEFAULT 1 CHECK (parcelas >= 1)
);

CREATE TABLE avaliacao (
  id_avaliacao BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_agendamento BIGINT NOT NULL UNIQUE REFERENCES agendamento(id_agendamento) ON UPDATE CASCADE ON DELETE RESTRICT,
  nota INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5),
  comentario TEXT,
  data_avaliacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- FUNÇÕES E TRIGGERS
-- =========================
CREATE OR REPLACE FUNCTION fn_recalcular_totais_agendamento(p_id_agendamento BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE agendamento a
  SET
    total_mao_de_obra = COALESCE((
      SELECT SUM(total_item) FROM item_servico WHERE id_agendamento = p_id_agendamento
    ), 0),
    total_pecas = COALESCE((
      SELECT SUM(total_item) FROM item_peca WHERE id_agendamento = p_id_agendamento
    ), 0)
  WHERE a.id_agendamento = p_id_agendamento;
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalcular_totais_item_servico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM fn_recalcular_totais_agendamento(OLD.id_agendamento);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.id_agendamento <> NEW.id_agendamento THEN
      PERFORM fn_recalcular_totais_agendamento(OLD.id_agendamento);
    END IF;
    PERFORM fn_recalcular_totais_agendamento(NEW.id_agendamento);
    RETURN NEW;
  ELSE
    PERFORM fn_recalcular_totais_agendamento(NEW.id_agendamento);
    RETURN NEW;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_recalcular_totais_item_peca()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM fn_recalcular_totais_agendamento(OLD.id_agendamento);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.id_agendamento <> NEW.id_agendamento THEN
      PERFORM fn_recalcular_totais_agendamento(OLD.id_agendamento);
    END IF;
    PERFORM fn_recalcular_totais_agendamento(NEW.id_agendamento);
    RETURN NEW;
  ELSE
    PERFORM fn_recalcular_totais_agendamento(NEW.id_agendamento);
    RETURN NEW;
  END IF;
END;
$$;

CREATE TRIGGER tg_item_servico_recalcula_totais
AFTER INSERT OR UPDATE OR DELETE ON item_servico
FOR EACH ROW EXECUTE FUNCTION trg_recalcular_totais_item_servico();

CREATE TRIGGER tg_item_peca_recalcula_totais
AFTER INSERT OR UPDATE OR DELETE ON item_peca
FOR EACH ROW EXECUTE FUNCTION trg_recalcular_totais_item_peca();

CREATE OR REPLACE FUNCTION fn_validar_pagamento_os_concluida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_status dm_status_os;
BEGIN
  SELECT status INTO v_status FROM agendamento WHERE id_agendamento = NEW.id_agendamento;
  IF v_status IS DISTINCT FROM 'Concluído' THEN
    RAISE EXCEPTION 'Pagamento só pode ser registrado para OS concluída. OS %, status atual: %', NEW.id_agendamento, v_status;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER tg_validar_pagamento_os_concluida
BEFORE INSERT OR UPDATE ON pagamento
FOR EACH ROW EXECUTE FUNCTION fn_validar_pagamento_os_concluida();

CREATE OR REPLACE FUNCTION fn_validar_avaliacao_os_concluida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_status dm_status_os;
BEGIN
  SELECT status INTO v_status FROM agendamento WHERE id_agendamento = NEW.id_agendamento;
  IF v_status IS DISTINCT FROM 'Concluído' THEN
    RAISE EXCEPTION 'Avaliação só pode ser registrada para OS concluída. OS %, status atual: %', NEW.id_agendamento, v_status;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER tg_validar_avaliacao_os_concluida
BEFORE INSERT OR UPDATE ON avaliacao
FOR EACH ROW EXECUTE FUNCTION fn_validar_avaliacao_os_concluida();
