
const CREDIT_PRODUCTS = {
  personal: {
    label: "Prestamo Efectivo BanBif",
    annualRate: 0.899,
    tceaRate: 0.9142,
    insuranceMonthlyRate: 0.0007,
    minAmount: 1000,
    maxAmount: 80000,
    minMonths: 6,
    maxMonths: 60,
    referenceAmount: 5000,
    referenceMonths: 12,
    referenceMonthlyPayment: 585.08,
  },
  vehicular: {
    label: "Credito Vehicular BanBif",
    annualRate: 0.3999,
    tceaRate: 0.4994,
    insuranceMonthlyRate: 0.0007,
    minAmount: 15000,
    maxAmount: 120000,
    minMonths: 12,
    maxMonths: 72,
  },
};

function selectCreditRules(product = "") {
  const key = String(product || "").toLowerCase();
  if (key.includes("vehicular")) return CREDIT_PRODUCTS.vehicular;
  return CREDIT_PRODUCTS.personal;
}

function annuityPayment(principal, monthlyRate, months) {
  const factor = Math.pow(1 + monthlyRate, months);
  if (factor === 1) return principal / months;
  return principal * ((monthlyRate * factor) / (factor - 1));
}

function minimumIncome({ product, location, incomeType }) {
  const isVehicular = String(product || "").toLowerCase().includes("vehicular");
  const isProvince = String(location || "").toLowerCase().includes("provincia");
  const isVariable = String(incomeType || "").toLowerCase().includes("variable");

  if (isVehicular) return isProvince ? 1500 : 1700;
  if (isVariable) return 2000;
  return isProvince ? 1200 : 1500;
}

function documentList(incomeCategory, maritalStatus) {
  const category = String(incomeCategory || "").toLowerCase();
  const docs = ["DNI del titular", "Sustento de ingresos"];

  if (String(maritalStatus || "").toLowerCase() === "casado") {
    docs.push("DNI y documentacion del conyuge");
  }

  if (category.includes("5ta")) {
    docs.push("1 boleta de pago si ingreso fijo o 3 ultimas si ingreso variable");
  } else if (category.includes("4ta")) {
    docs.push("2 ultimas DJ Anual SUNAT, 3 recibos por honorarios y declaraciones SUNAT de 3 meses");
  } else if (category.includes("2da")) {
    docs.push("2 ultimas DJ SUNAT de renta y constancia de ingresos actuales");
  } else if (category.includes("1ra")) {
    docs.push("DJ SUNAT o abonos bancarios, pagos SUNAT, autovaluo HR/PU y contratos de alquiler");
  }

  return docs;
}

export function calculateCreditPlan({
  product = "Prestamo Efectivo BanBif",
  amount,
  months,
  monthlyIncome,
  location = "Lima",
  incomeType = "fijo",
  incomeCategory = "5ta",
  employmentType = "dependiente",
  employmentMonths = 12,
  maritalStatus = "soltero",
  spouseDocuments = "no",
  badCreditHistory = "no",
}) {
  const principal = Number(amount || 0);
  const term = Number(months || 0);
  const income = Number(monthlyIncome || 0);
  const seniority = Number(employmentMonths || 0);
  const rules = selectCreditRules(product);
  const monthlyRate = Math.pow(1 + rules.annualRate, 1 / 12) - 1;
  const minIncome = minimumIncome({ product: rules.label, location, incomeType });

  const emptyResult = {
    ...rules,
    monthlyRate,
    baseMonthlyPayment: 0,
    monthlyInsurance: 0,
    monthlyPayment: 0,
    totalPayment: 0,
    totalInterest: 0,
    totalCost: 0,
    debtRatio: 0,
    minimumIncome: minIncome,
    risk: "Sin datos",
    decision: "Completar datos",
    canSubmit: false,
    recommendation: "Completa monto, plazo, ingreso y requisitos para simular la cuota.",
    requiredDocuments: documentList(incomeCategory, maritalStatus),
  };

  if (principal <= 0 || term <= 0 || income <= 0) {
    return emptyResult;
  }

  let baseMonthlyPayment = annuityPayment(principal, monthlyRate, term);
  let monthlyInsurance = principal * rules.insuranceMonthlyRate;
  let monthlyPayment = baseMonthlyPayment + monthlyInsurance;

  if (rules.referenceAmount && rules.referenceMonths && rules.referenceMonthlyPayment) {
    const refBase = annuityPayment(rules.referenceAmount, monthlyRate, rules.referenceMonths);
    const refInsurance = rules.referenceAmount * rules.insuranceMonthlyRate;
    const calibration = rules.referenceMonthlyPayment / (refBase + refInsurance);
    monthlyPayment = monthlyPayment * calibration;
    baseMonthlyPayment = Math.max(monthlyPayment - monthlyInsurance, 0);
  }

  const totalPayment = monthlyPayment * term;
  const totalInterest = Math.max(totalPayment - principal, 0);
  const totalCost = totalInterest;
  const debtRatio = monthlyPayment / income;

  let risk = "Bajo";
  let decision = "Viable para evaluacion";
  let canSubmit = true;
  let recommendation = "La cuota estimada se encuentra dentro de una capacidad de pago prudente.";

  const isIndependent = String(employmentType || "").toLowerCase().includes("independiente");
  const minSeniority = isIndependent ? 24 : 12;

  if (principal < rules.minAmount) {
    risk = "No elegible";
    decision = "Monto menor al minimo";
    canSubmit = false;
    recommendation = `El monto minimo referencial para ${rules.label} es S/ ${rules.minAmount.toLocaleString("es-PE")}.`;
  } else if (principal > rules.maxAmount) {
    risk = "No elegible";
    decision = "Monto fuera de politica";
    canSubmit = false;
    recommendation = `El monto solicitado supera el maximo referencial de ${rules.label}.`;
  } else if (term < rules.minMonths || term > rules.maxMonths) {
    risk = "No elegible";
    decision = "Plazo fuera de politica";
    canSubmit = false;
    recommendation = `El plazo permitido para ${rules.label} es de ${rules.minMonths} a ${rules.maxMonths} meses.`;
  } else if (income < minIncome) {
    risk = "No elegible";
    decision = "Ingreso minimo no cumple";
    canSubmit = false;
    recommendation = `El ingreso neto minimo referencial es S/ ${minIncome.toLocaleString("es-PE")}.`;
  } else if (seniority < minSeniority) {
    risk = "No elegible";
    decision = "Antiguedad laboral insuficiente";
    canSubmit = false;
    recommendation = `La antiguedad minima es ${minSeniority} meses para ${isIndependent ? "independiente" : "dependiente"}.`;
  } else if (String(badCreditHistory).toLowerCase() === "si") {
    risk = "No elegible";
    decision = "Central de riesgo adversa";
    canSubmit = false;
    recommendation = "No debe presentar mala calificacion en centrales de riesgo.";
  } else if (String(maritalStatus).toLowerCase() === "casado" && String(spouseDocuments).toLowerCase() !== "si") {
    risk = "No elegible";
    decision = "Falta documentacion del conyuge";
    canSubmit = false;
    recommendation = "Si el cliente es casado, debe presentar documentacion del conyuge.";
  } else if (monthlyPayment > income) {
    risk = "No elegible";
    decision = "Sin capacidad de pago";
    canSubmit = false;
    recommendation = "La cuota estimada supera el ingreso mensual declarado.";
  } else if (debtRatio > 0.4) {
    risk = "No elegible";
    decision = "RDS no permitido";
    canSubmit = false;
    recommendation = "La relacion cuota / ingreso supera el 40%. Reduce monto, aumenta plazo o sustenta mayor ingreso.";
  } else if (debtRatio > 0.3) {
    risk = "Medio";
    decision = "Requiere evaluacion estricta";
    recommendation = "La cuota es alta frente al ingreso. El caso puede pasar a evaluacion estricta.";
  }

  return {
    ...rules,
    monthlyRate,
    baseMonthlyPayment,
    monthlyInsurance,
    monthlyPayment,
    totalPayment,
    totalInterest,
    totalCost,
    debtRatio,
    minimumIncome: minIncome,
    risk,
    decision,
    canSubmit,
    recommendation,
    requiredDocuments: documentList(incomeCategory, maritalStatus),
  };
}

export function getBalanceAfterOperation(balance, amount) {
  return Number(balance || 0) - Number(amount || 0);
}

export function isInsufficientBalance(balance, amount) {
  return Number(amount || 0) > Number(balance || 0);
}

export function getBankAlerts({ accounts, credits }) {
  const alerts = [];

  if ((accounts || []).length === 0) {
    alerts.push("No tienes cuentas activas");
  }

  const pendingCredits = (credits || []).filter((credit) =>
    String(credit.status || "").toLowerCase().includes("evalu")
  );

  if (pendingCredits.length > 0) {
    alerts.push(`${pendingCredits.length} credito(s) en evaluacion`);
  }

  return alerts;
}
