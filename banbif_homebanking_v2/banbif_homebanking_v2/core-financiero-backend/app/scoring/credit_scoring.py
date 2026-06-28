def pick(data: dict, *keys, default=None):
    for key in keys:
        if key in data and data[key] not in (None, ""):
            return data[key]

    return default


def to_float(value, default=0.0):
    try:
        return float(value)
    except Exception:
        return default


def calcular_scoring(solicitud: dict):
    monto = to_float(
        pick(
            solicitud,
            "amount",
            "monto",
            "loan_amount",
            "requested_amount",
            "credit_amount",
            default=0
        )
    )

    plazo = to_float(
        pick(
            solicitud,
            "term_months",
            "plazo_meses",
            "months",
            "term",
            default=0
        )
    )

    ingreso = to_float(
        pick(
            solicitud,
            "monthly_income",
            "ingreso_mensual",
            "income",
            "salary",
            default=0
        )
    )

    score = 70
    factores = []

    if monto <= 0:
        score -= 10
        factores.append("No se encontro un monto valido para evaluar.")
    else:
        factores.append(f"Monto solicitado evaluado: {monto:.2f}.")

    if ingreso <= 0:
        score -= 25
        factores.append("No se encontro ingreso mensual valido.")
    else:
        factores.append(f"Ingreso mensual evaluado: {ingreso:.2f}.")

    if plazo <= 0:
        score -= 10
        factores.append("No se encontro plazo valido.")
    else:
        factores.append(f"Plazo evaluado: {plazo:.0f} meses.")

    if monto > 0 and ingreso > 0 and plazo > 0:
        cuota_aprox = monto / plazo
        ratio_cuota = cuota_aprox / ingreso
        ratio_monto_ingreso = monto / ingreso

        if ratio_cuota <= 0.25:
            score += 15
            factores.append("La cuota aproximada es baja frente al ingreso mensual.")
        elif ratio_cuota <= 0.40:
            score += 5
            factores.append("La cuota aproximada es aceptable frente al ingreso mensual.")
        elif ratio_cuota <= 0.60:
            score -= 15
            factores.append("La cuota aproximada es elevada frente al ingreso mensual.")
        else:
            score -= 30
            factores.append("La cuota aproximada representa alto riesgo de pago.")

        if ratio_monto_ingreso <= 6:
            score += 10
            factores.append("El monto total solicitado es manejable segun el ingreso.")
        elif ratio_monto_ingreso <= 12:
            factores.append("El monto total solicitado es moderado segun el ingreso.")
        else:
            score -= 15
            factores.append("El monto total solicitado es alto segun el ingreso.")

    if plazo > 0:
        if plazo <= 12:
            score += 10
            factores.append("El plazo corto reduce el riesgo crediticio.")
        elif plazo <= 36:
            score += 5
            factores.append("El plazo medio mantiene un riesgo controlado.")
        elif plazo > 60:
            score -= 10
            factores.append("El plazo largo aumenta el riesgo crediticio.")

    score = max(0, min(100, score))

    if score >= 80:
        riesgo = "BAJO"
        recomendacion = "APROBAR"
    elif score >= 60:
        riesgo = "MEDIO"
        recomendacion = "REVISAR"
    else:
        riesgo = "ALTO"
        recomendacion = "RECHAZAR"

    return {
        "score": round(score, 2),
        "riesgo": riesgo,
        "recomendacion": recomendacion,
        "factores": factores,
        "datos_usados": {
            "monto": monto,
            "plazo_meses": plazo,
            "ingreso_mensual": ingreso
        }
    }
