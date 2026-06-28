param(
  [string]$PgHost = "localhost",
  [string]$PgPort = "5432",
  [string]$PgUser = "postgres",
  [string]$DbName = "bd_core_financiero"
)

$ErrorActionPreference = "Stop"

Write-Host "===================================================="
Write-Host " BANBIF - EJECUCION COMPLETA PARA PROYECTO"
Write-Host "===================================================="

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Psql {
  $cmd = Get-Command psql -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $candidates = Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter "psql.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending

  if ($candidates.Count -gt 0) {
    return $candidates[0].FullName
  }

  throw "No se encontro psql.exe. Instale PostgreSQL o agregue PostgreSQL\\bin al PATH."
}

$psql = Find-Psql
Write-Host "psql encontrado en: $psql" -ForegroundColor Green

$pgPassword = Read-Host "Ingrese la password del usuario PostgreSQL '$PgUser'"
$env:PGPASSWORD = $pgPassword

try {
  Write-Host "`n1) Creando base de datos $DbName ..." -ForegroundColor Cyan

  & $psql `
    -h $PgHost `
    -p $PgPort `
    -U $PgUser `
    -d postgres `
    -v ON_ERROR_STOP=1 `
    -f "$baseDir\00_crear_base_datos.sql"

  if ($LASTEXITCODE -ne 0) {
    throw "Fallo creando la base de datos."
  }

  Write-Host "`n2) Creando tablas e insertando datos ..." -ForegroundColor Cyan

  & $psql `
    -h $PgHost `
    -p $PgPort `
    -U $PgUser `
    -d $DbName `
    -v ON_ERROR_STOP=1 `
    -f "$baseDir\01_esquema_y_datos_banbif.sql"

  if ($LASTEXITCODE -ne 0) {
    throw "Fallo ejecutando schema y datos."
  }

  Write-Host "`n3) Ejecutando validacion final ..." -ForegroundColor Cyan

  & $psql `
    -h $PgHost `
    -p $PgPort `
    -U $PgUser `
    -d $DbName `
    -v ON_ERROR_STOP=1 `
    -f "$baseDir\02_validacion_final.sql"

  if ($LASTEXITCODE -ne 0) {
    throw "Fallo ejecutando validacion final."
  }

  Write-Host "`n===================================================="
  Write-Host " TODO EJECUTADO CORRECTAMENTE" -ForegroundColor Green
  Write-Host " Base creada: $DbName"
  Write-Host " Ahora puede levantar Homebanking y Core."
  Write-Host "===================================================="
}
finally {
  Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}


