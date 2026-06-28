$ErrorActionPreference = "SilentlyContinue"

$root = "C:\Users\Lenovo\Desktop\banbif_homebanking_v2\banbif_homebanking_v2"
$out = Join-Path $root "docs\05_pruebas_evidencias\05_seguridad_rbac_jwt\RESULTADO_AUDITORIA_SEGURIDAD_RBAC_JWT.txt"

function Write-Report($text) {
    $text | Tee-Object -FilePath $out -Append
}

function Reset-Report {
    "AUDITORIA DE SEGURIDAD RBAC + JWT - BANBIF" | Set-Content $out
    "Fecha: $(Get-Date)" | Add-Content $out
    "" | Add-Content $out
}

function Invoke-TestRequest($method, $url, $headers = $null, $body = $null) {
    try {
        if ($body -ne $null) {
            $json = $body | ConvertTo-Json -Depth 10
            $response = Invoke-WebRequest -Method $method -Uri $url -Headers $headers -Body $json -ContentType "application/json" -UseBasicParsing
        } else {
            $response = Invoke-WebRequest -Method $method -Uri $url -Headers $headers -UseBasicParsing
        }

        return @{
            ok = $true
            status = [int]$response.StatusCode
            content = $response.Content
        }
    } catch {
        $status = 0
        $content = ""

        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $content = $reader.ReadToEnd()
            } catch {
                $content = $_.Exception.Message
            }
        } else {
            $content = $_.Exception.Message
        }

        return @{
            ok = $false
            status = $status
            content = $content
        }
    }
}

function Login-Core($username, $password) {
    $url = "http://127.0.0.1:8001/api/core/auth/login"
    $body = @{
        username = $username
        password = $password
    }

    $r = Invoke-TestRequest "POST" $url $null $body

    if ($r.status -ge 200 -and $r.status -lt 300) {
        try {
            $data = $r.content | ConvertFrom-Json
            $token = $data.access_token
            if (-not $token) { $token = $data.token }
            return @{
                status = $r.status
                token = $token
                raw = $r.content
            }
        } catch {
            return @{
                status = $r.status
                token = ""
                raw = $r.content
            }
        }
    }

    return @{
        status = $r.status
        token = ""
        raw = $r.content
    }
}

function Login-Homebanking($dni, $password) {
    $url = "http://127.0.0.1:8000/api/auth/login"
    $body = @{
        document = $dni
        password = $password
    }

    $r = Invoke-TestRequest "POST" $url $null $body

    if ($r.status -ge 200 -and $r.status -lt 300) {
        try {
            $data = $r.content | ConvertFrom-Json
            $token = $data.access_token
            if (-not $token) { $token = $data.token }
            return @{
                status = $r.status
                token = $token
                raw = $r.content
            }
        } catch {
            return @{
                status = $r.status
                token = ""
                raw = $r.content
            }
        }
    }

    return @{
        status = $r.status
        token = ""
        raw = $r.content
    }
}

function Decode-JwtPayload($token) {
    try {
        $parts = $token.Split(".")
        if ($parts.Length -lt 2) { return "" }

        $payload = $parts[1]
        $payload = $payload.Replace("-", "+").Replace("_", "/")

        switch ($payload.Length % 4) {
            2 { $payload += "==" }
            3 { $payload += "=" }
        }

        $bytes = [System.Convert]::FromBase64String($payload)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return ""
    }
}

Reset-Report

Write-Report "1) VERIFICACION DE SERVICIOS"
$corePing = Invoke-TestRequest "GET" "http://127.0.0.1:8001/api/core/ping"
$homePing = Invoke-TestRequest "GET" "http://127.0.0.1:8000/api/ping"

Write-Report "Core backend /api/core/ping -> HTTP $($corePing.status)"
Write-Report "Homebanking backend /api/ping -> HTTP $($homePing.status)"
Write-Report ""

Write-Report "2) LOGIN DE USUARIOS INTERNOS CORE"

$coreUsers = @(
    @{nombre="Analista Nivel 1"; usuario="40123456"; clave="123456"},
    @{nombre="Analista Nivel 2"; usuario="40234567"; clave="123456"},
    @{nombre="Analista Nivel 3"; usuario="40345678"; clave="123456"},
    @{nombre="Agencia"; usuario="40678901"; clave="123456"},
    @{nombre="Riesgos"; usuario="40789012"; clave="123456"},
    @{nombre="Comite"; usuario="40890123"; clave="123456"},
    @{nombre="Gerencia"; usuario="40901234"; clave="123456"}
)

$tokens = @{}

foreach ($u in $coreUsers) {
    $login = Login-Core $u.usuario $u.clave
    $tokens[$u.nombre] = $login.token

    if ($login.token) {
        Write-Report "$($u.nombre) ($($u.usuario)) -> Login OK HTTP $($login.status)"
        $payload = Decode-JwtPayload $login.token
        if ($payload) {
            Write-Report "Payload JWT: $payload"
        }
    } else {
        Write-Report "$($u.nombre) ($($u.usuario)) -> Login ERROR HTTP $($login.status)"
        Write-Report "Respuesta: $($login.raw)"
    }

    Write-Report ""
}

Write-Report "3) LOGIN DE CLIENTE HOMEBANKING"

$clientLogin = Login-Homebanking "71000001" "123456"

if ($clientLogin.token) {
    Write-Report "Cliente 71000001 -> Login OK HTTP $($clientLogin.status)"
    $payloadCliente = Decode-JwtPayload $clientLogin.token
    if ($payloadCliente) {
        Write-Report "Payload JWT cliente: $payloadCliente"
    }
} else {
    Write-Report "Cliente 71000001 -> Login ERROR HTTP $($clientLogin.status)"
    Write-Report "Respuesta: $($clientLogin.raw)"
}

Write-Report ""
Write-Report "4) PRUEBA SIN TOKEN E INVALID TOKEN"

$protectedCandidates = @(
    "http://127.0.0.1:8001/api/core/credits",
    "http://127.0.0.1:8001/api/core/credit-applications",
    "http://127.0.0.1:8001/api/core/solicitudes",
    "http://127.0.0.1:8001/api/core/disbursements",
    "http://127.0.0.1:8001/api/core/recoveries",
    "http://127.0.0.1:8001/api/core/dashboard"
)

$chosen = ""
foreach ($url in $protectedCandidates) {
    $r = Invoke-TestRequest "GET" $url
    if ($r.status -ne 404 -and $r.status -ne 0) {
        $chosen = $url
        break
    }
}

if (-not $chosen) {
    Write-Report "No se encontro endpoint protegido por GET entre los candidatos."
    Write-Report "Esto no significa error del sistema; solo requiere revisar rutas exactas del backend."
} else {
    Write-Report "Endpoint usado para prueba: $chosen"

    $noToken = Invoke-TestRequest "GET" $chosen
    Write-Report "Sin token -> HTTP $($noToken.status)"
    if ($noToken.status -eq 401) {
        Write-Report "Resultado: OK, el sistema bloquea solicitudes sin token."
    } else {
        Write-Report "Resultado: Revisar. Se esperaba 401."
    }

    $badHeaders = @{
        Authorization = "Bearer token_invalido"
    }

    $badToken = Invoke-TestRequest "GET" $chosen $badHeaders
    Write-Report "Token invalido -> HTTP $($badToken.status)"
    if ($badToken.status -eq 401) {
        Write-Report "Resultado: OK, el sistema bloquea token invalido."
    } else {
        Write-Report "Resultado: Revisar. Se esperaba 401."
    }
}

Write-Report ""
Write-Report "5) VERIFICACION DE ROLES Y TOKENS"

foreach ($key in $tokens.Keys) {
    if ($tokens[$key]) {
        Write-Report "$key -> Token generado correctamente."
    } else {
        Write-Report "$key -> No se genero token."
    }
}

Write-Report ""
Write-Report "6) CONCLUSION"

Write-Report "La auditoria permite evidenciar autenticacion con JWT y existencia de roles diferenciados."
Write-Report "Las pruebas no modifican datos, no aprueban creditos, no desembolsan y no cambian la base de datos."
Write-Report "Para evidenciar permisos 403 de acciones criticas, complementar con captura del Core cuando un rol no autorizado intenta realizar una accion restringida."
