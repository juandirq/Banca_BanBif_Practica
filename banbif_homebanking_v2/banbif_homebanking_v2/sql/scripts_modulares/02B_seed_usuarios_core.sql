-- 02B_seed_usuarios_core.sql
-- Usuarios internos del banco
-- Clave demo para todos: 123456

INSERT INTO core_analyst_user (
    full_name,
    username,
    email,
    role,
    position_name,
    approval_level,
    max_approval_amount,
    password_hash,
    is_active
)
VALUES
(
    'Ana Rojas Valdivia',
    'ana.rojas',
    'ana.rojas@banbif.local',
    'ASESOR_JUNIOR_1',
    'Asesor Junior 1',
    1,
    3000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Luis Paredes Huaman',
    'luis.paredes',
    'luis.paredes@banbif.local',
    'ASESOR_JUNIOR_2',
    'Asesor Junior 2',
    2,
    7000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Maria Torres Salinas',
    'maria.torres',
    'maria.torres@banbif.local',
    'ANALISTA_JUNIOR',
    'Analista Junior',
    3,
    12000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Carlos Rivas Delgado',
    'carlos.rivas',
    'carlos.rivas@banbif.local',
    'ANALISTA_SENIOR',
    'Analista Senior',
    4,
    25000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Lucia Salazar Montalvo',
    'lucia.salazar',
    'lucia.salazar@banbif.local',
    'SUPERVISOR',
    'Supervisor de Creditos',
    5,
    50000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Jorge Medina Cardenas',
    'jorge.medina',
    'jorge.medina@banbif.local',
    'RIESGOS',
    'Especialista de Riesgos',
    6,
    100000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Comite de Creditos BanBif',
    'comite.creditos',
    'comite.creditos@banbif.local',
    'COMITE',
    'Comite de Creditos',
    7,
    999999,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Administrador Core BanBif',
    'admin.core',
    'admin.core@banbif.local',
    'ADMIN',
    'Administrador del Sistema',
    8,
    999999,
    crypt('123456', gen_salt('bf')),
    TRUE
)
ON CONFLICT (username)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    position_name = EXCLUDED.position_name,
    approval_level = EXCLUDED.approval_level,
    max_approval_amount = EXCLUDED.max_approval_amount,
    password_hash = EXCLUDED.password_hash,
    is_active = TRUE;

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
    'SEED_USUARIOS_CORE',
    'core_analyst_user',
    NULL,
    'Carga de usuarios internos con niveles de asesor, analista, riesgos, comite y administrador.'
);