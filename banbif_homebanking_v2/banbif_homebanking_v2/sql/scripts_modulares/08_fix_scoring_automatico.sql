-- 08_fix_scoring_automatico.sql
-- Calcula score, RDS, semaforo y ruta cuando una solicitud no tiene evaluacion

CREATE OR REPLACE FUNCTION fn_credit_scoring_defaults()
RETURNS trigger AS $$
DECLARE
    v_cuota numeric;
    v_rds numeric;
    v_score integer;
    v_riesgo text;
    v_semaforo text;
    v_ruta text;
    v_nivel integer;
BEGIN
    v_cuota := ROUND(
        (COALESCE(NEW.amount, 0)::numeric * 1.18) / NULLIF(COALESCE(NEW.months, 12), 0),
        2
    );

    v_rds := ROUND(
        v_cuota / NULLIF(COALESCE(NEW.monthly_income, 0)::numeric, 0),
        4
    );

    IF v_rds IS NULL THEN
        v_rds := 0;
    END IF;

    v_score := CASE
        WHEN v_rds <= 0.25 AND COALESCE(NEW.amount, 0) <= 7000 THEN 92
        WHEN v_rds <= 0.35 AND COALESCE(NEW.amount, 0) <= 12000 THEN 78
        WHEN v_rds <= 0.45 THEN 64
        WHEN v_rds <= 0.60 THEN 52
        ELSE 38
    END;

    IF COALESCE(NEW.amount, 0) > 25000 THEN
        v_score := v_score - 6;
    END IF;

    IF v_score < 0 THEN
        v_score := 0;
    END IF;

    v_riesgo := CASE
        WHEN v_score >= 80 THEN 'BAJO'
        WHEN v_score >= 55 THEN 'MEDIO'
        ELSE 'ALTO'
    END;

    v_semaforo := CASE
        WHEN v_riesgo = 'BAJO' THEN 'VERDE'
        WHEN v_riesgo = 'MEDIO' THEN 'AMARILLO'
        ELSE 'ROJO'
    END;

    v_ruta := CASE
        WHEN COALESCE(NEW.status, '') = 'En comite' THEN 'COMITE'
        WHEN v_riesgo = 'ALTO' AND COALESCE(NEW.amount, 0) > 12000 THEN 'RIESGOS'
        WHEN COALESCE(NEW.amount, 0) <= 3000 THEN 'ANALISTA_N1'
        WHEN COALESCE(NEW.amount, 0) <= 7000 THEN 'ANALISTA_N2'
        WHEN COALESCE(NEW.amount, 0) <= 12000 THEN 'ANALISTA_N3'
        WHEN COALESCE(NEW.amount, 0) <= 25000 THEN 'ANALISTA_N4'
        WHEN COALESCE(NEW.amount, 0) <= 40000 THEN 'SENIOR_CREDITOS'
        WHEN COALESCE(NEW.amount, 0) <= 60000 THEN 'ADMIN_AGENCIA'
        WHEN COALESCE(NEW.amount, 0) <= 150000 THEN 'GERENCIA'
        ELSE 'COMITE'
    END;

    v_nivel := CASE
        WHEN v_ruta = 'ANALISTA_N1' THEN 1
        WHEN v_ruta = 'ANALISTA_N2' THEN 2
        WHEN v_ruta = 'ANALISTA_N3' THEN 3
        WHEN v_ruta = 'ANALISTA_N4' THEN 4
        WHEN v_ruta = 'SENIOR_CREDITOS' THEN 5
        WHEN v_ruta = 'ADMIN_AGENCIA' THEN 6
        WHEN v_ruta = 'RIESGOS' THEN 7
        WHEN v_ruta = 'GERENCIA' THEN 8
        WHEN v_ruta = 'COMITE' THEN 9
        ELSE 1
    END;

    NEW.estimated_installment := COALESCE(NEW.estimated_installment, v_cuota::double precision);
    NEW.rds_ratio := COALESCE(NULLIF(NEW.rds_ratio, 0), v_rds::double precision);
    NEW.scoring_score := COALESCE(NULLIF(NEW.scoring_score, 0), v_score);
    NEW.risk_level := COALESCE(NULLIF(TRIM(NEW.risk_level), ''), v_riesgo);
    NEW.risk_semaphore := COALESCE(NULLIF(TRIM(NEW.risk_semaphore), ''), v_semaforo);
    NEW.approval_route := COALESCE(NULLIF(TRIM(NEW.approval_route), ''), v_ruta);
    NEW.required_approval_level := COALESCE(NULLIF(NEW.required_approval_level, 0), v_nivel);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_credit_scoring_defaults ON creditapplication;

CREATE TRIGGER trg_credit_scoring_defaults
BEFORE INSERT OR UPDATE OF amount, months, monthly_income, status
ON creditapplication
FOR EACH ROW
EXECUTE FUNCTION fn_credit_scoring_defaults();

UPDATE creditapplication
SET
    estimated_installment = NULL,
    rds_ratio = 0,
    scoring_score = 0,
    risk_level = NULL,
    risk_semaphore = NULL,
    approval_route = NULL,
    required_approval_level = NULL
WHERE
    scoring_score IS NULL
    OR scoring_score = 0
    OR risk_level IS NULL
    OR TRIM(COALESCE(risk_level, '')) = ''
    OR approval_route IS NULL
    OR TRIM(COALESCE(approval_route, '')) = '';

UPDATE creditapplication
SET amount = amount
WHERE
    scoring_score IS NULL
    OR scoring_score = 0
    OR risk_level IS NULL
    OR TRIM(COALESCE(risk_level, '')) = ''
    OR approval_route IS NULL
    OR TRIM(COALESCE(approval_route, '')) = '';

INSERT INTO audit_log (
    actor_type,
    actor_id,
    action,
    entity,
    entity_id,
    detail
)
VALUES (
    'SYSTEM',
    NULL,
    'FIX_SCORING_AUTOMATICO',
    'creditapplication',
    NULL,
    'Se agrega trigger para calcular score, RDS, semaforo, ruta y nivel requerido en solicitudes nuevas o incompletas.'
);