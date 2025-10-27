Write-Host "Iniciando SQL Server para pruebas..." -ForegroundColor Green

# Verificar que Docker este corriendo
try {
  docker info | Out-Null
}
catch {
  Write-Host "Docker no esta corriendo. Por favor inicia Docker Desktop." -ForegroundColor Red
  exit 1
}

# Levantar el contenedor
Write-Host "Levantando contenedor SQL Server..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
  Write-Host "Error al levantar el contenedor" -ForegroundColor Red
  exit 1
}

# Esperar a que SQL Server este listo
Write-Host "Esperando a que SQL Server este disponible..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

do {
  $attempt++
  Start-Sleep -Seconds 3
    
  try {
    docker exec sqltest-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "4dm1nC4rd10" -Q "SELECT 1" -C 2>$null
    if ($LASTEXITCODE -eq 0) {
      break
    }
  }
  catch {
    # Continuar intentando
  }
    
  Write-Host "  Intento $attempt de $maxAttempts..." -ForegroundColor Gray
} while ($attempt -lt $maxAttempts)

if ($attempt -ge $maxAttempts) {
  Write-Host "SQL Server no respondio despues de $maxAttempts intentos" -ForegroundColor Red
  docker-compose logs sqlserver
  exit 1
}

# Verificar si la base de datos TestDB ya existe
Write-Host "Verificando base de datos TestDB..." -ForegroundColor Yellow
$dbCheck = docker exec sqltest-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "4dm1nC4rd10" -Q "SELECT name FROM sys.databases WHERE name = 'TestDB'" -C -h -1 2>$null

if (-not ($dbCheck -match "TestDB")) {
  Write-Host "Creando base de datos TestDB..." -ForegroundColor Yellow
  docker exec sqltest-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "4dm1nC4rd10" -Q "CREATE DATABASE TestDB;" -C

  if ($LASTEXITCODE -eq 0) {
    Write-Host "Creando tabla de ejemplo..." -ForegroundColor Yellow
    docker exec sqltest-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "4dm1nC4rd10" -Q "USE TestDB; CREATE TABLE Users (Id INT IDENTITY(1,1) PRIMARY KEY, Name NVARCHAR(100) NOT NULL, Email NVARCHAR(255) NOT NULL, CreatedAt DATETIME2 DEFAULT GETDATE());" -C

    Write-Host "Insertando datos de prueba..." -ForegroundColor Yellow
    docker exec sqltest-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "4dm1nC4rd10" -Q "USE TestDB; INSERT INTO Users (Name, Email) VALUES ('Juan Perez', 'juan.perez@email.com'), ('Maria Garcia', 'maria.garcia@email.com'), ('Carlos Lopez', 'carlos.lopez@email.com');" -C
  }
}
else {
  Write-Host "Base de datos TestDB ya existe" -ForegroundColor Green
}

Write-Host ""
Write-Host "SQL Server esta listo para usar!" -ForegroundColor Green
Write-Host ""
Write-Host "Informacion de conexion:" -ForegroundColor Cyan
Write-Host "  Servidor: localhost,1433" -ForegroundColor White
Write-Host "  Base de datos: TestDB" -ForegroundColor White
Write-Host "  Usuario: sa" -ForegroundColor White
Write-Host "  Contrasena: 4dm1nC4rd10" -ForegroundColor White
Write-Host ""
Write-Host "Cadena de conexion para tu aplicacion:" -ForegroundColor Cyan
Write-Host "  Server=localhost,1433;Database=TestDB;User Id=sa;Password=4dm1nC4rd10;TrustServerCertificate=true;" -ForegroundColor White
Write-Host ""
Write-Host "Comandos utiles:" -ForegroundColor Yellow
Write-Host "  - Verificar estado: docker-compose ps" -ForegroundColor Gray
Write-Host "  - Ver logs: docker-compose logs" -ForegroundColor Gray
Write-Host "  - Detener: docker-compose down" -ForegroundColor Gray
Write-Host "  - Conectar con SSMS: localhost,1433 (usuario: sa)" -ForegroundColor Gray