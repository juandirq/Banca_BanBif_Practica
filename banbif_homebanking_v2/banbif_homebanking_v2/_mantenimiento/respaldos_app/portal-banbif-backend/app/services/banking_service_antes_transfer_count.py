from datetime import datetime
from decimal import Decimal
from random import randint
from sqlalchemy import text
from sqlalchemy.orm import Session
from fastapi import HTTPException


def row_to_dict(row) -> dict:
    return dict(row._mapping) if row else {}


def rows_to_list(rows) -> list[dict]:
    return [dict(row._mapping) for row in rows]


def get_table_columns(db: Session, table_name: str) -> set[str]:
    result = db.execute(
        text("""
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = :table_name
        """),
        {"table_name": table_name},
    ).fetchall()

    return {r[0] for r in result}


def get_dashboard_preview(db: Session, user_id) -> dict:
    if not user_id:
        return {
            "total_balance": 0,
            "accounts_count": 0,
            "accounts": [],
            "last_movements": [],
        }

    accounts = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE user_id = :user_id
            ORDER BY id ASC
        """),
        {"user_id": user_id},
    ).fetchall()

    accounts_list = rows_to_list(accounts)
    account_ids = [a.get("id") for a in accounts_list if a.get("id") is not None]

    total_balance = sum(
        Decimal(str(a.get("balance", 0) or 0))
        for a in accounts_list
    )

    movements = []

    if account_ids:
        movements = db.execute(
            text("""
                SELECT *
                FROM public.movement
                WHERE account_id = ANY(:account_ids)
                ORDER BY created_at DESC
                LIMIT 100
            """),
            {"account_ids": account_ids},
        ).fetchall()

    return {
        "total_balance": float(total_balance),
        "accounts_count": len(accounts_list),
        "accounts": accounts_list,
        "last_movements": rows_to_list(movements),
    }


def get_full_dashboard(db: Session, user_id) -> dict:
    preview = get_dashboard_preview(db, user_id)

    credits = db.execute(
        text("""
            SELECT *
            FROM public.creditapplication
            WHERE user_id = :user_id
            ORDER BY created_at DESC
            LIMIT 100
        """),
        {"user_id": user_id},
    ).fetchall()

    payments = db.execute(
        text("""
            SELECT *
            FROM public.pagos
            WHERE user_id = :user_id
            ORDER BY created_at DESC
            LIMIT 100
        """),
        {"user_id": user_id},
    ).fetchall()

    preview["credits"] = rows_to_list(credits)
    preview["payments"] = rows_to_list(payments)

    return preview



def create_account(db: Session, user_id, account_type: str, currency: str) -> dict:
    cols = get_table_columns(db, "account")

    account_type = str(account_type or "").strip()
    currency = str(currency or "PEN").upper().strip()

    if account_type != "Cuenta Ahorro Digital":
        raise HTTPException(
            status_code=400,
            detail="Desde Homebanking solo se permite abrir Cuenta Ahorro Digital. Cuenta Sueldo y Cuenta Corriente requieren validacion del banco.",
        )

    if currency not in ("PEN", "USD"):
        raise HTTPException(status_code=400, detail="Moneda no permitida para apertura digital.")

    type_col = "type" if "type" in cols else "account_type" if "account_type" in cols else None

    active_count = db.execute(
        text("""
            SELECT COUNT(*)
            FROM public.account
            WHERE user_id = :user_id
            AND status = 'Activa'
        """),
        {"user_id": user_id},
    ).scalar()

    if int(active_count or 0) >= 3:
        raise HTTPException(
            status_code=400,
            detail="Limite referencial de 3 cuentas digitales activas alcanzado para la demo.",
        )

    if type_col:
        duplicate = db.execute(
            text(f"""
                SELECT id
                FROM public.account
                WHERE user_id = :user_id
                AND {type_col} = :account_type
                AND currency = :currency
                AND status = 'Activa'
                LIMIT 1
            """),
            {"user_id": user_id, "account_type": account_type, "currency": currency},
        ).fetchone()

        if duplicate:
            raise HTTPException(
                status_code=400,
                detail="Ya tienes una Cuenta Ahorro Digital activa en esa moneda.",
            )

    account_number = "191" + str(randint(1000000000, 9999999999))

    values = {}

    if "user_id" in cols:
        values["user_id"] = user_id
    if "account_number" in cols:
        values["account_number"] = account_number
    if "type" in cols:
        values["type"] = account_type
    elif "account_type" in cols:
        values["account_type"] = account_type
    if "currency" in cols:
        values["currency"] = currency
    if "balance" in cols:
        values["balance"] = 0
    if "status" in cols:
        values["status"] = "Activa"
    if "created_at" in cols:
        values["created_at"] = datetime.now()

    columns_sql = ", ".join(values.keys())
    params_sql = ", ".join([f":{key}" for key in values.keys()])

    row = db.execute(
        text(f"""
            INSERT INTO public.account ({columns_sql})
            VALUES ({params_sql})
            RETURNING *
        """),
        values,
    ).fetchone()

    db.commit()
    return row_to_dict(row)



def make_transfer(db: Session, user_id, from_account_id: int, to_account_number: str, amount: Decimal, description: str, token_digital: str):
    if str(token_digital or "").strip() != "123456":
        raise HTTPException(status_code=401, detail="Token Digital invalido.")

    if amount < Decimal("1"):
        raise HTTPException(status_code=400, detail="El monto minimo de operacion es S/ 1.00.")

    if amount > Decimal("2000"):
        raise HTTPException(status_code=400, detail="El limite por operacion para transferencias es S/ 2000.00.")

    origin = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE id = :account_id
            AND user_id = :user_id
            LIMIT 1
        """),
        {"account_id": from_account_id, "user_id": user_id},
    ).fetchone()

    if not origin:
        raise HTTPException(status_code=404, detail="La cuenta origen no existe.")

    origin_account = row_to_dict(origin)
    origin_balance = Decimal(str(origin_account.get("balance", 0) or 0))

    if origin_balance < amount:
        raise HTTPException(status_code=400, detail="Saldo insuficiente para realizar la transferencia.")

    if str(origin_account.get("account_number")) == str(to_account_number):
        raise HTTPException(status_code=400, detail="No puedes transferir a la misma cuenta.")

    daily_sent = db.execute(
        text("""
            SELECT COALESCE(SUM(ABS(amount)), 0)
            FROM public.movement
            WHERE account_id = :account_id
            AND amount < 0
            AND operation_type ILIKE '%Transferencia%'
            AND operation_type NOT ILIKE '%PLIN%'
            AND DATE(created_at) = CURRENT_DATE
        """),
        {"account_id": from_account_id},
    ).scalar()

    if Decimal(str(daily_sent or 0)) + amount > Decimal("5000"):
        raise HTTPException(status_code=400, detail="Superas el limite diario referencial de transferencias de S/ 5000.00.")

    destination = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE account_number = :account_number
            AND status = 'Activa'
            LIMIT 1
        """),
        {"account_number": to_account_number},
    ).fetchone()

    if not destination:
        raise HTTPException(status_code=404, detail="La cuenta destino no existe.")

    destination_account = row_to_dict(destination)

    db.execute(
        text("""
            UPDATE public.account
            SET balance = balance - :amount
            WHERE id = :origin_id
        """),
        {"amount": amount, "origin_id": from_account_id},
    )

    db.execute(
        text("""
            UPDATE public.account
            SET balance = balance + :amount
            WHERE id = :destination_id
        """),
        {"amount": amount, "destination_id": destination_account["id"]},
    )

    db.execute(
        text("""
            INSERT INTO public.movement (account_id, description, operation_type, amount, created_at)
            VALUES (:account_id, :description, :operation_type, :amount, :created_at)
        """),
        {
            "account_id": from_account_id,
            "operation_type": "Transferencia enviada",
            "description": description,
            "amount": -amount,
            "created_at": datetime.now(),
        },
    )

    db.execute(
        text("""
            INSERT INTO public.movement (account_id, description, operation_type, amount, created_at)
            VALUES (:account_id, :description, :operation_type, :amount, :created_at)
        """),
        {
            "account_id": destination_account["id"],
            "operation_type": "Transferencia recibida",
            "description": description,
            "amount": amount,
            "created_at": datetime.now(),
        },
    )

    db.commit()

    return {
        "message": "Transferencia realizada correctamente.",
        "amount": float(amount),
        "to_account_number": to_account_number,
    }


def request_credit(db: Session, user_id, product: str, amount: Decimal, term_months: int, monthly_income: Decimal, purpose: str):
    if amount <= 0:
        raise HTTPException(status_code=400, detail="El monto solicitado debe ser mayor a cero.")

    if monthly_income <= 0:
        raise HTTPException(status_code=400, detail="El ingreso mensual debe ser mayor a cero.")

    cols = get_table_columns(db, "creditapplication")

    values = {}

    if "user_id" in cols:
        values["user_id"] = user_id
    if "product" in cols:
        values["product"] = product
    if "amount" in cols:
        values["amount"] = amount
    if "term_months" in cols:
        values["term_months"] = term_months
    elif "months" in cols:
        values["months"] = term_months
    if "monthly_income" in cols:
        values["monthly_income"] = monthly_income
    if "purpose" in cols:
        values["purpose"] = purpose
    if "status" in cols:
        values["status"] = "En evaluacion"

    columns_sql = ", ".join(values.keys())
    params_sql = ", ".join([f":{key}" for key in values.keys()])

    row = db.execute(
        text(f"""
            INSERT INTO public.creditapplication ({columns_sql})
            VALUES ({params_sql})
            RETURNING *
        """),
        values,
    ).fetchone()

    db.commit()

    return {
        "message": "Solicitud de credito registrada correctamente.",
        "credit": row_to_dict(row),
    }



def register_payment(db: Session, user_id, account_id: int, service: str, contract_number: str, amount: Decimal, token_digital: str):
    if str(token_digital or "").strip() != "123456":
        raise HTTPException(status_code=401, detail="Token Digital invalido.")

    if amount < Decimal("1"):
        raise HTTPException(status_code=400, detail="El monto minimo de operacion es S/ 1.00.")

    service_key = str(service or "").lower()

    if "tarjeta" in service_key and "credito" in service_key and amount < Decimal("30"):
        raise HTTPException(
            status_code=400,
            detail="El pago minimo referencial de tarjeta de credito BanBif debe ser como minimo S/ 30.00."
        )

    if amount > Decimal("2000"):
        raise HTTPException(status_code=400, detail="El limite por operacion para pagos es S/ 2000.00.")

    daily_paid = db.execute(
        text("""
            SELECT COALESCE(SUM(ABS(amount)), 0)
            FROM public.movement
            WHERE account_id = :account_id
            AND amount < 0
            AND operation_type ILIKE '%Pago%'
            AND DATE(created_at) = CURRENT_DATE
        """),
        {"account_id": account_id},
    ).scalar()

    if Decimal(str(daily_paid or 0)) + amount > Decimal("5000"):
        raise HTTPException(status_code=400, detail="Superas el limite diario referencial de pagos de S/ 5000.00.")

    account = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE id = :account_id
            AND user_id = :user_id
            LIMIT 1
        """),
        {"account_id": account_id, "user_id": user_id},
    ).fetchone()

    if not account:
        raise HTTPException(status_code=404, detail="La cuenta no existe.")

    account_data = row_to_dict(account)
    balance = Decimal(str(account_data.get("balance", 0) or 0))

    if balance < amount:
        raise HTTPException(status_code=400, detail="Saldo insuficiente para pagar el servicio.")

    db.execute(
        text("""
            UPDATE public.account
            SET balance = balance - :amount
            WHERE id = :account_id
        """),
        {"amount": amount, "account_id": account_id},
    )

    cols = get_table_columns(db, "pagos")

    values = {}

    if "user_id" in cols:
        values["user_id"] = user_id
    if "account_id" in cols:
        values["account_id"] = account_id
    if "servicio" in cols:
        values["servicio"] = service
    elif "service" in cols:
        values["service"] = service
    if "numero_contrato" in cols:
        values["numero_contrato"] = contract_number
    elif "contract_number" in cols:
        values["contract_number"] = contract_number
    if "monto" in cols:
        values["monto"] = amount
    elif "amount" in cols:
        values["amount"] = amount
    if "estado" in cols:
        values["estado"] = "Procesado"
    elif "status" in cols:
        values["status"] = "Procesado"
    if "created_at" in cols:
        values["created_at"] = datetime.now()

    columns_sql = ", ".join(values.keys())
    params_sql = ", ".join([f":{key}" for key in values.keys()])

    row = db.execute(
        text(f"""
            INSERT INTO public.pagos ({columns_sql})
            VALUES ({params_sql})
            RETURNING *
        """),
        values,
    ).fetchone()

    db.execute(
        text("""
            INSERT INTO public.movement (account_id, description, operation_type, amount, created_at)
            VALUES (:account_id, :description, :operation_type, :amount, :created_at)
        """),
        {
            "account_id": account_id,
            "operation_type": "Pago de servicio",
            "description": f"Pago de {service}",
            "amount": -amount,
            "created_at": datetime.now(),
        },
    )

    db.commit()

    return {
        "message": "Pago realizado correctamente.",
        "payment": row_to_dict(row),
    }


def make_deposit(db: Session, user_id, account_id: int, amount: Decimal, description: str):
    if amount < Decimal("1"):
        raise HTTPException(status_code=400, detail="El monto minimo de operacion es S/ 1.00.")

    account = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE id = :account_id
            AND user_id = :user_id
            LIMIT 1
        """),
        {
            "account_id": account_id,
            "user_id": user_id,
        },
    ).fetchone()

    if not account:
        raise HTTPException(status_code=404, detail="La cuenta no existe o no pertenece al usuario.")

    db.execute(
        text("""
            UPDATE public.account
            SET balance = balance + :amount
            WHERE id = :account_id
            AND user_id = :user_id
        """),
        {
            "amount": amount,
            "account_id": account_id,
            "user_id": user_id,
        },
    )

    db.execute(
        text("""
            INSERT INTO public.movement
            (account_id, description, operation_type, amount, created_at)
            VALUES
            (:account_id, :description, :operation_type, :amount, :created_at)
        """),
        {
            "account_id": account_id,
            "description": description,
            "operation_type": "Deposito",
            "amount": amount,
            "created_at": datetime.now(),
        },
    )

    db.commit()

    updated_account = db.execute(
        text("""
            SELECT *
            FROM public.account
            WHERE id = :account_id
            LIMIT 1
        """),
        {"account_id": account_id},
    ).fetchone()

    return {
        "message": "Deposito realizado correctamente.",
        "account": row_to_dict(updated_account),
        "amount": float(amount),
    }


# VERSION FINAL BANBIF CREDITOS - Prestamo Efectivo y Credito Vehicular
def _banbif_credit_rules(product: str) -> dict:
    product_key = str(product or "").lower()

    if "vehicular" in product_key:
        return {
            "label": "Credito Vehicular BanBif",
            "annual_rate": 0.3999,
            "tcea_rate": 0.4994,
            "insurance_monthly_rate": 0.0007,
            "min_amount": 15000,
            "max_amount": 120000,
            "min_months": 12,
            "max_months": 72,
            "reference_amount": None,
            "reference_months": None,
            "reference_payment": None,
        }

    return {
        "label": "Prestamo Efectivo BanBif",
        "annual_rate": 0.899,
        "tcea_rate": 0.9142,
        "insurance_monthly_rate": 0.0007,
        "min_amount": 1000,
        "max_amount": 80000,
        "min_months": 6,
        "max_months": 60,
        "reference_amount": 5000,
        "reference_months": 12,
        "reference_payment": 585.08,
    }


def _annuity(principal: float, monthly_rate: float, months: int) -> float:
    factor = (1 + monthly_rate) ** months
    if factor == 1:
        return principal / months
    return principal * ((monthly_rate * factor) / (factor - 1))


def _minimum_income(product: str, location: str, income_type: str) -> Decimal:
    is_vehicular = "vehicular" in str(product or "").lower()
    is_province = "provincia" in str(location or "").lower()
    is_variable = "variable" in str(income_type or "").lower()

    if is_vehicular:
        return Decimal("1500") if is_province else Decimal("1700")
    if is_variable:
        return Decimal("2000")
    return Decimal("1200") if is_province else Decimal("1500")


def _documents_by_category(income_category: str, marital_status: str) -> str:
    category = str(income_category or "").lower()
    docs = ["DNI del titular", "Sustento de ingresos"]

    if str(marital_status or "").lower() == "casado":
        docs.append("DNI y documentacion del conyuge")

    if "5ta" in category:
        docs.append("1 boleta de pago si ingreso fijo o 3 ultimas si ingreso variable")
    elif "4ta" in category:
        docs.append("2 ultimas DJ Anual SUNAT, 3 recibos por honorarios y declaraciones SUNAT de 3 meses")
    elif "2da" in category:
        docs.append("2 ultimas DJ SUNAT de renta y constancia de ingresos actuales")
    elif "1ra" in category:
        docs.append("DJ SUNAT o abonos bancarios, pagos SUNAT, autovaluo HR/PU y contratos de alquiler")

    return " | ".join(docs)


def _employment_type_by_category(income_category: str) -> str:
    category = str(income_category or "").lower()

    if "5ta" in category:
        return "dependiente"
    if "4ta" in category:
        return "independiente"
    if "2da" in category:
        return "rentas de 2da categoria"
    if "1ra" in category:
        return "rentas de 1ra categoria"

    return "dependiente"


def _minimum_seniority_by_category(income_category: str) -> int:
    category = str(income_category or "").lower()
    return 12 if "5ta" in category else 24


def _simulate_banbif_credit(product: str, amount: Decimal, term_months: int, monthly_income: Decimal) -> dict:
    rules = _banbif_credit_rules(product)
    principal = float(amount)
    term = int(term_months)
    income = float(monthly_income)
    monthly_rate = (1 + rules["annual_rate"]) ** (1 / 12) - 1

    base = _annuity(principal, monthly_rate, term)
    insurance = principal * rules["insurance_monthly_rate"]
    monthly_payment = base + insurance

    if rules["reference_amount"] and rules["reference_months"] and rules["reference_payment"]:
        ref_base = _annuity(float(rules["reference_amount"]), monthly_rate, int(rules["reference_months"]))
        ref_insurance = float(rules["reference_amount"]) * rules["insurance_monthly_rate"]
        calibration = float(rules["reference_payment"]) / (ref_base + ref_insurance)
        monthly_payment = monthly_payment * calibration
        base = max(monthly_payment - insurance, 0)

    total_payment = monthly_payment * term
    total_interest = max(total_payment - principal, 0)
    debt_ratio = monthly_payment / income if income > 0 else 999

    risk = "Bajo"
    decision = "Viable para evaluacion"
    analyst_route = "Analista Nivel 1"

    if debt_ratio > 0.30:
        risk = "Medio"
        decision = "Requiere evaluacion estricta"
        analyst_route = "Analista Nivel 3"

    return {
        "rules": rules,
        "principal": principal,
        "term": term,
        "income": income,
        "monthly_rate": monthly_rate,
        "base_monthly_payment": base,
        "monthly_insurance": insurance,
        "monthly_payment": monthly_payment,
        "total_payment": total_payment,
        "total_interest": total_interest,
        "total_cost": total_interest,
        "debt_ratio": debt_ratio,
        "risk": risk,
        "decision": decision,
        "analyst_route": analyst_route,
    }


def request_credit(
    db: Session,
    user_id,
    product: str,
    amount: Decimal,
    term_months: int,
    monthly_income: Decimal,
    purpose: str,
    location: str = "Lima",
    income_type: str = "fijo",
    income_category: str = "5ta",
    employment_type: str = "dependiente",
    employment_months: int = 12,
    marital_status: str = "soltero",
    spouse_documents: str = "no",
    bad_credit_history: str = "no",
):
    if amount <= 0:
        raise HTTPException(status_code=400, detail="El monto solicitado debe ser mayor a cero.")

    if term_months <= 0:
        raise HTTPException(status_code=400, detail="El plazo debe ser mayor a cero.")

    if monthly_income <= 0:
        raise HTTPException(status_code=400, detail="El ingreso mensual debe ser mayor a cero.")

    simulation = _simulate_banbif_credit(product, amount, term_months, monthly_income)
    rules = simulation["rules"]

    min_income = _minimum_income(rules["label"], location, income_type)
    employment_type = _employment_type_by_category(income_category)

    if amount < Decimal(str(rules["min_amount"])):
        raise HTTPException(status_code=400, detail=f"Solicitud no elegible: el monto minimo para {rules['label']} es S/ {rules['min_amount']:,.2f}.")

    if amount > Decimal(str(rules["max_amount"])):
        raise HTTPException(status_code=400, detail=f"Solicitud no elegible: el monto supera el maximo referencial para {rules['label']}.")

    if term_months < rules["min_months"] or term_months > rules["max_months"]:
        raise HTTPException(status_code=400, detail=f"Solicitud no elegible: el plazo permitido para {rules['label']} es de {rules['min_months']} a {rules['max_months']} meses.")

    if monthly_income < min_income:
        raise HTTPException(status_code=400, detail=f"Solicitud no elegible: ingreso neto minimo referencial S/ {min_income:,.2f}.")

    seniority = int(employment_months or 0)
    min_seniority = _minimum_seniority_by_category(income_category)

    if seniority < min_seniority:
        raise HTTPException(status_code=400, detail=f"Solicitud no elegible: antiguedad minima {min_seniority} meses.")

    if str(bad_credit_history or "").lower() == "si":
        raise HTTPException(status_code=400, detail="Solicitud no elegible: no debe presentar mala calificacion en centrales de riesgo.")

    if str(marital_status or "").lower() == "casado" and str(spouse_documents or "").lower() != "si":
        raise HTTPException(status_code=400, detail="Solicitud no elegible: falta documentacion del conyuge.")

    if simulation["monthly_payment"] > simulation["income"]:
        raise HTTPException(status_code=400, detail="Solicitud no elegible: la cuota estimada supera el ingreso mensual declarado.")

    if simulation["debt_ratio"] > 0.40:
        raise HTTPException(status_code=400, detail="Solicitud no elegible: la relacion cuota / ingreso supera el 40%.")

    documents = _documents_by_category(income_category, marital_status)

    analyst_comment = (
        "Solicitud registrada desde Homebanking. "
        f"Producto: {rules['label']}. "
        f"Proposito: {purpose}. "
        f"TEA referencial: {rules['annual_rate'] * 100:.2f}%. "
        f"TCEA referencial: {rules['tcea_rate'] * 100:.2f}%. "
        f"Cuota estimada: S/ {simulation['monthly_payment']:.2f}. "
        f"Seguro desgravamen mensual estimado: S/ {simulation['monthly_insurance']:.2f}. "
        f"Total a pagar: S/ {simulation['total_payment']:.2f}. "
        f"RDS: {simulation['debt_ratio'] * 100:.2f}%. "
        f"Ubicacion: {location}. Tipo ingreso: {income_type}. Categoria: {income_category}. "
        f"Situacion laboral: {employment_type}. Antiguedad meses: {employment_months}. "
        f"Estado civil: {marital_status}. Central de riesgo: pendiente de validacion interna. Documentos requeridos: {documents}. "
        f"Riesgo referencial: {simulation['risk']}. Ruta sugerida: {simulation['analyst_route']}."
    )

    cols = get_table_columns(db, "creditapplication")

    values = {}

    if "user_id" in cols:
        values["user_id"] = user_id
    if "product" in cols:
        values["product"] = rules["label"]
    if "amount" in cols:
        values["amount"] = amount
    if "term_months" in cols:
        values["term_months"] = term_months
    elif "months" in cols:
        values["months"] = term_months
    if "monthly_income" in cols:
        values["monthly_income"] = monthly_income
    if "purpose" in cols:
        values["purpose"] = purpose
    if "status" in cols:
        values["status"] = "En evaluacion"
    if "analyst_comment" in cols:
        values["analyst_comment"] = analyst_comment
    if "created_at" in cols:
        values["created_at"] = datetime.now()

    optional_values = {
        "tea": rules["annual_rate"],
        "annual_rate": rules["annual_rate"],
        "tcea": rules["tcea_rate"],
        "tcea_rate": rules["tcea_rate"],
        "monthly_payment": simulation["monthly_payment"],
        "cuota_estimada": simulation["monthly_payment"],
        "monthly_insurance": simulation["monthly_insurance"],
        "seguro_desgravamen": simulation["monthly_insurance"],
        "total_payment": simulation["total_payment"],
        "total_to_pay": simulation["total_payment"],
        "debt_ratio": simulation["debt_ratio"],
        "rds": simulation["debt_ratio"],
        "risk": simulation["risk"],
        "riesgo": simulation["risk"],
    }

    for column, value in optional_values.items():
        if column in cols:
            values[column] = value

    columns_sql = ", ".join(values.keys())
    params_sql = ", ".join([f":{key}" for key in values.keys()])

    row = db.execute(
        text(f"""
            INSERT INTO public.creditapplication ({columns_sql})
            VALUES ({params_sql})
            RETURNING *
        """),
        values,
    ).fetchone()

    db.commit()

    return {
        "message": "Solicitud de credito registrada correctamente.",
        "credit": row_to_dict(row),
        "simulation": {
            "product": rules["label"],
            "tea": round(rules["annual_rate"] * 100, 2),
            "tcea": round(rules["tcea_rate"] * 100, 2),
            "monthly_payment": round(simulation["monthly_payment"], 2),
            "monthly_insurance": round(simulation["monthly_insurance"], 2),
            "total_payment": round(simulation["total_payment"], 2),
            "debt_ratio": round(simulation["debt_ratio"] * 100, 2),
            "risk": simulation["risk"],
            "decision": simulation["decision"],
            "analyst_route": simulation["analyst_route"],
        },
    }

