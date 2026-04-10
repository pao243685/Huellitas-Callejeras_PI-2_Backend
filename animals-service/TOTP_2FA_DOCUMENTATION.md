# Implementación de TOTP (Autenticación de dos factores)

## 📋 Resumen de cambios

Se ha implementado TOTP (Time-based One-Time Password) para 2FA usando `otplib` y `qrcode`. Los cambios afectan:

- ✅ **Schema Prisma**: Agregados campos `twoFactorSecret` y `twoFactorEnabled` al modelo `Usuario`
- ✅ **Servicio 2FA**: `TwoFactorService` con lógica de generación, validación y gestión de secrets
- ✅ **Controlador 2FA**: `TwoFactorController` con 4 endpoints consolidados y eficientes
- ✅ **Auth Service**: Modificado flujo de login para detectar 2FA habilitado
- ✅ **Auth Module**: Registrado el nuevo servicio y controlador
- ✅ **Migración Prisma**: Agregadas columnas `twoFactorSecret` y `twoFactorEnabled`
- ✅ **DTOs**: Creados DTOs con validación usando class-validator

---

## 🔑 Endpoints de 2FA (Consolidados)

### **Resumen de endpoints (4 totales)**

| Endpoint | Método | Requiere JWT | Descripción |
|----------|--------|--------------|-----------|
| `/auth/me/2fa` | GET | ✅ | Ver status del 2FA |
| `/auth/me/2fa` | POST | ✅ | Generar QR (PASO 1) |
| `/auth/me/2fa` | PUT | ✅ | Activar/Desactivar (PASO 2) |
| `/auth/2fa/verify` | POST | ❌ | Verificar TOTP en login |

### ✨ **¿Por qué esta estructura?**

- ✅ **Menos endpoints redundantes**: 4 en lugar de 5-6
- ✅ **Más RESTful**: Usa métodos HTTP correctos (GET/POST/PUT)
- ✅ **Sin duplicación**: Todo se maneja en `/auth/me/2fa`
- ✅ **Eficiente**: El login normal NO se afecta para usuarios sin 2FA

---

## 📝 Endpoints Detallados

### 1. **GET /auth/me/2fa** - Ver estado actual
⚠️ Requiere JWT

```bash
curl -X GET http://localhost:3000/auth/me/2fa \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Respuesta (200 OK):**
```json
{
  "id_usuario": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "twoFactorEnabled": false
}
```

---

### 2. **POST /auth/me/2fa** - Generar QR (PASO 1)
⚠️ Requiere JWT

```bash
curl -X POST http://localhost:3000/auth/me/2fa \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Respuesta (201 Created):**
```json
{
  "secret": "JBSWY3DPEBLW64TMMQ======",
  "qrCodeUrl": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIQAAACECAYAAABccqhmAAAAfE...",
  "message": "Escanea este QR con tu app autenticadora. Guardaremos el secret cuando verifiques el código."
}
```

**Flujo:**
1. El frontend obtiene `secret` y `qrCodeUrl`
2. Muestra el QR en pantalla
3. El usuario escanea con Google Authenticator, Authy, etc.

---

### 3. **PUT /auth/me/2fa** - Activar/Desactivar 2FA (PASO 2)
⚠️ Requiere JWT + código válido (solo para activar)

#### **Activar 2FA:**
```bash
curl -X PUT http://localhost:3000/auth/me/2fa \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "123456",
    "secret": "JBSWY3DPEBLW64TMMQ======",
    "enabled": true
  }'
```

**Respuesta (200 OK):**
```json
{
  "id_usuario": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "twoFactorEnabled": true,
  "message": "2FA activado correctamente. Guarda tu secret en un lugar seguro."
}
```

#### **Desactivar 2FA:**
```bash
curl -X PUT http://localhost:3000/auth/me/2fa \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false
  }'
```

**Respuesta (200 OK):**
```json
{
  "id_usuario": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "twoFactorEnabled": false,
  "message": "2FA desactivado."
}
```

---

### 4. **POST /auth/2fa/verify** - Verificar TOTP en login
❌ NO requiere autenticación previa

Se usa después de `POST /auth/login` cuando `requires2FA: true`

```bash
curl -X POST http://localhost:3000/auth/2fa/verify \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "token": "123456"
  }'
```

**Respuesta (201 Created):**
```json
{
  "user": {
    "id_usuario": "550e8400-e29b-41d4-a716-446655440000",
    "nombre": "Juan",
    "apellido_p": "Pérez",
    "email": "juan@example.com",
    "activo": true,
    "twoFactorEnabled": true,
    "refugio": { ... },
    "rol": { ... }
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 🔄 Flujos de uso

### **Flujo 1: Activar 2FA (Primera vez)**

```
PASO 1: Usuario solicita activar 2FA
  Frontend: POST /auth/me/2fa (autenticado)
  ↓ Respuesta: { secret, qrCodeUrl }

PASO 2: Usuario escanea QR con app autenticadora
  App: Google Authenticator / Authy / etc.
  Usuario copia el código de 6 dígitos
  
PASO 3: Usuario verifica el código
  Frontend: PUT /auth/me/2fa { token: "123456", secret, enabled: true }
  ↓ Respuesta: { twoFactorEnabled: true }
  
✅ 2FA Activado
```

### **Flujo 2: Login CON 2FA Habilitado**

```
PASO 1: Usuario ingresa credenciales
  Frontend: POST /auth/login { email, password }
  Backend valida email + password
  
Si 2FA está habilitado:
  ↓ Respuesta: { requires2FA: true, userId }
  
PASO 2: Frontend muestra input para código TOTP
  Usuario abre app autenticadora
  Usuario ingresa código de 6 dígitos
  
PASO 3: Verificar código TOTP
  Frontend: POST /auth/2fa/verify { userId, token: "123456" }
  Backend valida el TOTP contra secret guardado
  ↓ Respuesta: { user, access_token: "JWT" }
  
✅ Login Completado - JWT válido
```

### **Flujo 3: Login SIN 2FA**

```
Frontend: POST /auth/login { email, password }
  ↓ Respuesta: { user, access_token: "JWT" }

✅ Login directo (sin verification 2FA)
```

### **Flujo 4: Desactivar 2FA**

```
Frontend: PUT /auth/me/2fa { enabled: false } (autenticado)
  ↓ Respuesta: { twoFactorEnabled: false }

✅ 2FA Desactivado
```

---

## 📊 Comparativa: ANTES vs DESPUÉS

### ANTES (5 endpoints redundantes):
```
POST /auth/2fa/setup
POST /auth/2fa/enable
GET /auth/2fa/status
POST /auth/2fa/disable
POST /auth/2fa/login
```

### DESPUÉS (4 endpoints eficientes):
```
GET  /auth/me/2fa        (ver status)
POST /auth/me/2fa        (generar QR)
PUT  /auth/me/2fa        (activar/desactivar)
POST /auth/2fa/verify    (verificar en login)
```

**Ventajas:**
✅ Menos endpoints
✅ Más RESTful (GET/POST/PUT)
✅ No duplica `/auth/login` para usuarios sin 2FA
✅ Fácil de entender

---

## 🚀 Deployment

Los cambios son **completamente transparentes** para CI/CD:

```
1. Git push → Cambios de código llegan a repo
2. Docker build → Incluye nuevas rutas/servicios
3. prisma migrate deploy → Se ejecuta automáticamente en EC2
4. ✅ Sin cambios en variables de entorno ni infraestructura
```

---

## 🔐 Seguridad

### Características implementadas:

✅ **Secrets nunca se devuelven en la API** (excepto en setup inicial)
- En setup devolvemos el secret para que lo guarde
- En todo lo demás está protegido en DB

✅ **Validación de TOTP**
- `otplib` usa RFC 6238 standard
- Ventana de tolerancia: ±1 step (30 segundos)
- Códigos de 6 dígitos

✅ **JWT sigue siendo el standard**
- 2FA es una capa adicional
- JWT expira cada 24h

✅ **DTOs con validación**
- Código debe ser exactamente 6 dígitos
- Todos los inputs validados

---

## 📱 Apps recomendadas para TOTP

- Google Authenticator
- Authy
- Microsoft Authenticator
- FreeOTP
- 1Password

---

## 📦 Archivos creados/modificados

### Creados:
- `src/auth/services/two-factor.service.ts`
- `src/auth/controllers/two-factor.controller.ts`
- `src/auth/dto/two-factor.dto.ts` (simplificado)
- `prisma/migrations/20260410000001_add_two_factor_columns/migration.sql`

### Modificados:
- `prisma/schema.prisma` (schema actualizado)
- `src/auth/services/auth.service.ts` (flujo 2FA en login)
- `src/auth/auth.module.ts` (registrar servicio y controlador)

---

## ✨ Próximos pasos opcionales

1. **Backup codes**: 10 códigos para emergencias
2. **Rate limiting**: Limitar intentos fallidos
3. **Auditoría**: Log de cambios 2FA
4. **SMS fallback**: Email o SMS como respaldo

---

**Implementación completada y lista para producción** ✅
