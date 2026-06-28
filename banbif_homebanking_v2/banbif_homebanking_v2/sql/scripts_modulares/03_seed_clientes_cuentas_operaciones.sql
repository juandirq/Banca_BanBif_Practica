-- 03_seed_clientes_cuentas_operaciones.sql
-- Clientes, cuentas, movimientos y pagos realistas
-- Proyecto BanBif - bd_core_financiero
-- Clave demo para clientes principales: 123456

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- LIMPIEZA SOLO DE DATOS DEMO DE CLIENTES
-- No toca usuarios internos del core
-- =========================================================

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
),
demo_accounts AS (
    SELECT id
    FROM account
    WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM pagos
WHERE user_id IN (SELECT id FROM demo_users)
   OR account_id IN (SELECT id FROM demo_accounts);

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
),
demo_accounts AS (
    SELECT id
    FROM account
    WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM movement
WHERE account_id IN (SELECT id FROM demo_accounts);

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
)
DELETE FROM creditapplication
WHERE user_id IN (SELECT id FROM demo_users);

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
)
DELETE FROM account
WHERE user_id IN (SELECT id FROM demo_users);

DELETE FROM "user"
WHERE email LIKE '%@demo.banbif.local';

-- =========================================================
-- CLIENTES DEMO REALISTAS
-- =========================================================

INSERT INTO "user" (
    document,
    full_name,
    email,
    password_hash,
    phone,
    address,
    role,
    is_active,
    created_at
)
SELECT
    '7' || LPAD(i::text, 7, '0') AS document,
    nombres.nombre AS full_name,
    'cliente.demo' || LPAD(i::text, 2, '0') || '@demo.banbif.local' AS email,
    crypt('123456', gen_salt('bf')) AS password_hash,
    '9' || LPAD((60000000 + i)::text, 8, '0') AS phone,
    direcciones.direccion AS address,
    'CLIENTE' AS role,
    TRUE AS is_active,
    (
        CASE
            WHEN i % 5 = 0 THEN DATE '2022-02-15'
            WHEN i % 5 = 1 THEN DATE '2023-05-10'
            WHEN i % 5 = 2 THEN DATE '2024-08-20'
            WHEN i % 5 = 3 THEN DATE '2025-03-12'
            ELSE DATE '2026-01-18'
        END
        + ((i % 25) || ' days')::interval
    ) AS created_at
FROM generate_series(1, 60) AS i
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Carlos Mendoza Alvarez',
        'Lucia Fernandez Quispe',
        'Miguel Torres Huaman',
        'Valeria Rojas Medina',
        'Andres Salazar Poma',
        'Camila Herrera Flores',
        'Diego Paredes Soto',
        'Sofia Castillo Ramos',
        'Jorge Ramirez Loayza',
        'Daniela Vargas Salas',
        'Sebastian Morales Vega',
        'Natalia Flores Palacios',
        'Renato Caceres Molina',
        'Andrea Medina Arias',
        'Bruno Aguilar Rios',
        'Mariana Lozano Cueva',
        'Esteban Vega Romero',
        'Paula Navarro Fuentes',
        'Hugo Campos Leon',
        'Fiorella Reyes Gonzales',
        'Raul Quintana Bravo',
        'Gabriela Leon Chavez',
        'Mateo Silva Ponce',
        'Alessandra Ponce Meza',
        'Rodrigo Chavez Lujan',
        'Fernanda Molina Vera',
        'Eduardo Prieto Solis',
        'Carolina Valdez Rivas',
        'Oscar Benavides Torres',
        'Milagros Ramos Nuñez',
        'Ivan Cordova Herrera',
        'Patricia Meza Delgado',
        'Luis Carranza Ortiz',
        'Claudia Roman Vargas',
        'Emilio Fuentes Diaz',
        'Rosa Palacios Espinoza',
        'Alonso Gutierrez Mendez',
        'Karla Espinoza Calderon',
        'Fernando Villanueva Robles',
        'Tamara Leon Valverde',
        'Julio Salinas Cardenas',
        'Monica Huerta Aguilar',
        'Victor Zamora Paredes',
        'Elena Bustamante Soto',
        'Ricardo Tapia Roman',
        'Rocio Andrade Vargas',
        'Manuel Herrera Caceres',
        'Carmen Valdivia Ramos',
        'Gustavo Cueva Medina',
        'Patricia Quiroz Torres',
        'Alberto Rojas Salcedo',
        'Marisol Campos Silva',
        'Nicolas Figueroa Bravo',
        'Diana Pizarro Flores',
        'Arturo Delgado Meza',
        'Beatriz Nuñez Arias',
        'Cristian Vera Palacios',
        'Lorena Quispe Lozano',
        'Hector Ramos Poma',
        'Vanessa Molina Salas'
    ])[i] AS nombre
) nombres
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Av. Javier Prado 1250 - Lima',
        'Av. Arequipa 2450 - Lima',
        'Jr. Real 340 - Huancayo',
        'Av. Los Incas 780 - Cusco',
        'Calle Comercio 450 - Arequipa',
        'Av. Guardia Civil 1150 - Lima',
        'Jr. Puno 220 - Juliaca',
        'Av. San Martin 980 - Trujillo',
        'Calle Grau 150 - Chiclayo',
        'Av. Universitaria 2010 - Lima'
    ])[1 + (i % 10)] AS direccion
) direcciones;

-- =========================================================
-- CUENTAS
-- Una cuenta principal por cliente y segunda cuenta para algunos
-- =========================================================

INSERT INTO account (
    user_id,
    account_number,
    account_type,
    currency,
    balance,
    status,
    created_at
)
SELECT
    u.id,
    '191' || LPAD(u.id::text, 9, '0') AS account_number,
    CASE
        WHEN u.id % 4 = 0 THEN 'Cuenta Corriente'
        ELSE 'Cuenta Ahorro Digital'
    END AS account_type,
    'PEN' AS currency,
    ROUND((850 + (u.id % 17) * 280 + random() * 1600)::numeric, 2)::double precision AS balance,
    'Activa' AS status,
    u.created_at + interval '1 day'
FROM "user" u
WHERE u.email LIKE '%@demo.banbif.local';

-- Segunda cuenta para aproximadamente un tercio
INSERT INTO account (
    user_id,
    account_number,
    account_type,
    currency,
    balance,
    status,
    created_at
)
SELECT
    u.id,
    '192' || LPAD(u.id::text, 9, '0') AS account_number,
    'Cuenta Ahorro Digital' AS account_type,
    'PEN' AS currency,
    ROUND((400 + (u.id % 11) * 210 + random() * 1200)::numeric, 2)::double precision AS balance,
    'Activa' AS status,
    u.created_at + interval '8 days'
FROM "user" u
WHERE u.email LIKE '%@demo.banbif.local'
  AND u.id % 3 = 0;

-- Algunas cuentas inactivas para realismo, sin afectar mayoría
UPDATE account
SET status = 'Inactiva'
WHERE id IN (
    SELECT a.id
    FROM account a
    JOIN "user" u ON u.id = a.user_id
    WHERE u.email LIKE '%@demo.banbif.local'
      AND a.id % 37 = 0
);

-- =========================================================
-- MOVIMIENTOS HISTORICOS 2022-2026
-- Operaciones bancarias realistas
-- =========================================================

INSERT INTO movement (
    account_id,
    description,
    operation_type,
    amount,
    created_at
)
SELECT
    a.id,
    CASE ops.tipo
        WHEN 'DEPOSITO' THEN 'Deposito recibido en cuenta'
        WHEN 'TRANSFERENCIA' THEN 'Transferencia a cuenta BanBif'
        WHEN 'PAGO' THEN 'Pago de servicio desde Homebanking'
        ELSE 'Retiro / consumo bancario'
    END AS description,
    ops.tipo AS operation_type,
    ROUND(
        CASE ops.tipo
            WHEN 'DEPOSITO' THEN (600 + random() * 2600)
            WHEN 'TRANSFERENCIA' THEN (80 + random() * 1200)
            WHEN 'PAGO' THEN (35 + random() * 450)
            ELSE (50 + random() * 750)
        END::numeric,
        2
    )::double precision AS amount,
    (
        make_date(anio.y, mes.m, 1)
        + ((a.id + mes.m + ops.orden) % 25 || ' days')::interval
        + ((ops.orden * 3) || ' hours')::interval
    ) AS created_at
FROM account a
JOIN "user" u ON u.id = a.user_id
CROSS JOIN generate_series(2022, 2026) AS anio(y)
CROSS JOIN generate_series(1, 12) AS mes(m)
CROSS JOIN (
    VALUES
        (1, 'DEPOSITO'),
        (2, 'TRANSFERENCIA'),
        (3, 'PAGO'),
        (4, 'RETIRO')
) AS ops(orden, tipo)
WHERE u.email LIKE '%@demo.banbif.local'
  AND a.status = 'Activa'
  AND make_date(anio.y, mes.m, 1) <= CURRENT_DATE
  AND (
        ops.tipo IN ('DEPOSITO', 'PAGO')
        OR (a.id + mes.m + anio.y + ops.orden) % 2 = 0
      );

-- =========================================================
-- PAGOS DE SERVICIOS HISTORICOS
-- =========================================================

INSERT INTO pagos (
    user_id,
    servicio,
    numero_contrato,
    monto,
    estado,
    created_at,
    account_id
)
SELECT
    a.user_id,
    servicios.nombre AS servicio,
    'CTR-' || a.id || '-' || anio.y || '-' || LPAD(mes.m::text, 2, '0') AS numero_contrato,
    ROUND(
        CASE servicios.nombre
            WHEN 'Luz' THEN (45 + random() * 190)
            WHEN 'Agua' THEN (25 + random() * 95)
            WHEN 'Internet' THEN (70 + random() * 150)
            WHEN 'Telefonia' THEN (35 + random() * 110)
            WHEN 'Tarjeta de credito' THEN (180 + random() * 980)
            ELSE (120 + random() * 720)
        END::numeric,
        2
    )::double precision AS monto,
    CASE
        WHEN (a.id + mes.m + anio.y) % 15 = 0 THEN 'Pendiente'
        ELSE 'Pagado'
    END AS estado,
    (
        make_date(anio.y, mes.m, 1)
        + ((a.id + mes.m) % 24 || ' days')::interval
        + interval '10 hours'
    ) AS created_at,
    a.id AS account_id
FROM account a
JOIN "user" u ON u.id = a.user_id
CROSS JOIN generate_series(2022, 2026) AS anio(y)
CROSS JOIN generate_series(1, 12) AS mes(m)
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Luz',
        'Agua',
        'Internet',
        'Telefonia',
        'Tarjeta de credito',
        'Prestamo'
    ])[1 + ((a.id + mes.m + anio.y) % 6)] AS nombre
) servicios
WHERE u.email LIKE '%@demo.banbif.local'
  AND a.status = 'Activa'
  AND make_date(anio.y, mes.m, 1) <= CURRENT_DATE
  AND (a.id + mes.m + anio.y) % 2 = 0;

-- =========================================================
-- AUDITORIA
-- =========================================================

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
    'SEED_CLIENTES_CUENTAS_OPERACIONES',
    'user/account/movement/pagos',
    NULL,
    'Carga de clientes, cuentas, movimientos y pagos historicos realistas 2022-2026.'
);