# Integración 2FA en Next.js Frontend

## 📝 Hook Personalizado para 2FA

```typescript
// hooks/use2FA.ts
import { useState } from 'react';
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface Setup2FAResponse {
  secret: string;
  qrCodeUrl: string;
  message: string;
}

interface Status2FAResponse {
  id_usuario: string;
  email: string;
  twoFactorEnabled: boolean;
}

interface LoginResponse {
  user: any;
  access_token: string;
}

export const use2FA = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * GET /auth/me/2fa
   * Obtiene el estado actual de 2FA
   */
  const getStatus = async (token: string): Promise<Status2FAResponse | null> => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get(
        `${API_BASE_URL}/auth/me/2fa`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      return response.data;
    } catch (err) {
      const message = axios.isAxiosError(err)
        ? err.response?.data?.message || 'Error al obtener estado'
        : 'Error desconocido';
      setError(message);
      return null;
    } finally {
      setLoading(false);
    }
  };

  /**
   * POST /auth/me/2fa
   * PASO 1: Genera secret TOTP y código QR
   */
  const generateQR = async (token: string): Promise<Setup2FAResponse | null> => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.post(
        `${API_BASE_URL}/auth/me/2fa`,
        {},
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      return response.data;
    } catch (err) {
      const message = axios.isAxiosError(err)
        ? err.response?.data?.message || 'Error al generar QR'
        : 'Error desconocido';
      setError(message);
      return null;
    } finally {
      setLoading(false);
    }
  };

  /**
   * PUT /auth/me/2fa
   * PASO 2: Activa 2FA después de validar el código
   */
  const enableTwoFactor = async (
    token: string,
    totpCode: string,
    secret: string
  ): Promise<Status2FAResponse | null> => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.put(
        `${API_BASE_URL}/auth/me/2fa`,
        {
          token: totpCode,
          secret,
          enabled: true,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      return response.data;
    } catch (err) {
      const message = axios.isAxiosError(err)
        ? err.response?.data?.message || 'Error al activar 2FA'
        : 'Error desconocido';
      setError(message);
      return null;
    } finally {
      setLoading(false);
    }
  };

  /**
   * PUT /auth/me/2fa con enabled=false
   * Desactiva 2FA
   */
  const disableTwoFactor = async (token: string): Promise<boolean> => {
    setLoading(true);
    setError(null);
    try {
      await axios.put(
        `${API_BASE_URL}/auth/me/2fa`,
        { enabled: false },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      return true;
    } catch (err) {
      const message = axios.isAxiosError(err)
        ? err.response?.data?.message || 'Error al desactivar 2FA'
        : 'Error desconocido';
      setError(message);
      return false;
    } finally {
      setLoading(false);
    }
  };

  /**
   * POST /auth/2fa/verify
   * Verifica TOTP después de POST /auth/login
   */
  const verifyTOTPAndLogin = async (
    userId: string,
    totpCode: string
  ): Promise<LoginResponse | null> => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.post(
        `${API_BASE_URL}/auth/2fa/verify`,
        {
          userId,
          token: totpCode,
        }
      );
      return response.data;
    } catch (err) {
      const message = axios.isAxiosError(err)
        ? err.response?.data?.message || 'Código TOTP inválido'
        : 'Error desconocido';
      setError(message);
      return null;
    } finally {
      setLoading(false);
    }
  };

  return {
    generateQR,
    enableTwoFactor,
    disableTwoFactor,
    verifyTOTPAndLogin,
    getStatus,
    loading,
    error,
    setError,
  };
};
```

---

## 🖼️ Componente para Activar 2FA

```typescript
// components/Enable2FAModal.tsx
'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';
import { use2FA } from '@/hooks/use2FA';

interface Enable2FAModalProps {
  token: string;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function Enable2FAModal({
  token,
  isOpen,
  onClose,
  onSuccess,
}: Enable2FAModalProps) {
  const { generateQR, enableTwoFactor, loading, error, setError } = use2FA();
  const [step, setStep] = useState<'setup' | 'verify'>('setup');
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [secret, setSecret] = useState<string | null>(null);
  const [totpCode, setTotpCode] = useState('');

  useEffect(() => {
    if (isOpen) {
      handleGenerateQR();
    }
  }, [isOpen]);

  const handleGenerateQR = async () => {
    const result = await generateQR(token);
    if (result) {
      setQrCode(result.qrCodeUrl);
      setSecret(result.secret);
      setStep('setup');
    }
  };

  const handleVerify = async () => {
    if (!secret) return;

    const result = await enableTwoFactor(token, totpCode, secret);
    if (result) {
      // Mostrar éxito
      alert('✅ 2FA activado correctamente. Guarda tu secret en lugar seguro.');
      onSuccess();
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div className="bg-white rounded-lg p-8 max-w-md w-full">
        <h2 className="text-2xl font-bold mb-6">Configurar 2FA</h2>

        {step === 'setup' && (
          <div className="space-y-4">
            <p className="text-gray-600">
              Escanea este código QR con tu app autenticadora (Google Authenticator, Authy, etc)
            </p>

            {qrCode && (
              <div className="flex justify-center bg-gray-100 p-4 rounded">
                <Image
                  src={qrCode}
                  alt="QR Code para 2FA"
                  width={200}
                  height={200}
                  priority
                />
              </div>
            )}

            <div className="bg-yellow-50 border border-yellow-200 rounded p-3">
              <p className="text-sm font-semibold text-yellow-800">Secret backup:</p>
              <code className="text-xs bg-yellow-100 p-2 rounded block break-all">
                {secret}
              </code>
              <p className="text-xs text-yellow-700 mt-2">
                💾 Guarda este código en un lugar seguro. Lo necesitarás si pierdes tu dispositivo.
              </p>
            </div>

            <button
              onClick={() => setStep('verify')}
              disabled={loading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50"
            >
              {loading ? 'Cargando...' : 'Siguiente'}
            </button>
          </div>
        )}

        {step === 'verify' && (
          <div className="space-y-4">
            <p className="text-gray-600">
              Ingresa el código de 6 dígitos de tu app autenticadora
            </p>

            <input
              type="text"
              maxLength={6}
              placeholder="000000"
              value={totpCode}
              onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, ''))}
              className="w-full border border-gray-300 rounded px-3 py-2 text-center text-2xl tracking-widest"
            />

            {error && <p className="text-red-600 text-sm">{error}</p>}

            <button
              onClick={handleVerify}
              disabled={loading || totpCode.length !== 6}
              className="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700 disabled:opacity-50"
            >
              {loading ? 'Verificando...' : 'Activar 2FA'}
            </button>

            <button
              onClick={() => {
                setStep('setup');
                setTotpCode('');
                setError(null);
              }}
              className="w-full bg-gray-200 text-gray-800 py-2 rounded hover:bg-gray-300"
            >
              Volver
            </button>
          </div>
        )}

        <button
          onClick={onClose}
          className="mt-4 w-full bg-gray-300 text-gray-800 py-2 rounded hover:bg-gray-400"
        >
          Cerrar
        </button>
      </div>
    </div>
  );
}
```

---

## 🔐 Componente para Login con 2FA

```typescript
// components/LoginWith2FA.tsx
'use client';

import { useState } from 'react';
import axios from 'axios';
import { use2FA } from '@/hooks/use2FA';
import { useRouter } from 'next/navigation';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export default function LoginWith2FA() {
  const router = useRouter();
  const { verifyTOTPAndLogin, loading, error } = use2FA();

  const [step, setStep] = useState<'credentials' | '2fa'>('credentials');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [totpCode, setTotpCode] = useState('');
  const [userId, setUserId] = useState<string | null>(null);
  const [loginError, setLoginError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleLoginStep1 = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setLoginError(null);

    try {
      const response = await axios.post(
        `${API_BASE_URL}/auth/login`,
        { email, contrasena: password }
      );

      // Si 2FA está habilitado
      if (response.data.requires2FA) {
        setUserId(response.data.userId);
        setStep('2fa');
      } else {
        // Login directo sin 2FA
        localStorage.setItem('token', response.data.access_token);
        router.push('/dashboard');
      }
    } catch (err) {
      setLoginError(
        axios.isAxiosError(err)
          ? err.response?.data?.message || 'Credenciales inválidas'
          : 'Error desconocido'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleLoginStep2 = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userId) return;

    const result = await verifyTOTPAndLogin(userId, totpCode);
    if (result) {
      localStorage.setItem('token', result.access_token);
      router.push('/dashboard');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white rounded-lg shadow-md p-8 w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6">Iniciar Sesión</h1>

        {step === 'credentials' && (
          <form onSubmit={handleLoginStep1} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="mt-1 w-full border border-gray-300 rounded px-3 py-2"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Contraseña</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="mt-1 w-full border border-gray-300 rounded px-3 py-2"
              />
            </div>

            {loginError && <p className="text-red-600 text-sm">{loginError}</p>}

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50"
            >
              {isLoading ? 'Cargando...' : 'Iniciar Sesión'}
            </button>
          </form>
        )}

        {step === '2fa' && (
          <form onSubmit={handleLoginStep2} className="space-y-4">
            <p className="text-gray-600 text-center">
              Ingresa el código de 6 dígitos de tu app autenticadora
            </p>

            <input
              type="text"
              maxLength={6}
              placeholder="000000"
              value={totpCode}
              onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, ''))}
              autoFocus
              className="w-full border border-gray-300 rounded px-3 py-2 text-center text-2xl tracking-widest"
            />

            {error && <p className="text-red-600 text-sm text-center">{error}</p>}

            <button
              type="submit"
              disabled={loading || totpCode.length !== 6}
              className="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700 disabled:opacity-50"
            >
              {loading ? 'Verificando...' : 'Verificar'}
            </button>

            <button
              type="button"
              onClick={() => {
                setStep('credentials');
                setTotpCode('');
              }}
              className="w-full bg-gray-200 text-gray-800 py-2 rounded hover:bg-gray-300"
            >
              Volver
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
```

---

## ⚙️ Página de Configuración de 2FA

```typescript
// app/settings/2fa/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { use2FA } from '@/hooks/use2FA';
import Enable2FAModal from '@/components/Enable2FAModal';

export default function TwoFactorSettings() {
  const { getStatus, disableTwoFactor, loading } = use2FA();
  const [status, setStatus] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [token] = useState(() => localStorage.getItem('token') || '');

  useEffect(() => {
    const checkStatus = async () => {
      const result = await getStatus(token);
      if (result) {
        setStatus(result);
      }
    };
    if (token) {
      checkStatus();
    }
  }, [token]);

  const handleDisable = async () => {
    if (confirm('¿Estás seguro? Desactivarás la verificación de 2 factores.')) {
      const success = await disableTwoFactor(token);
      if (success) {
        setStatus({ ...status, twoFactorEnabled: false });
      }
    }
  };

  return (
    <div className="max-w-md mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Autenticación de 2 Factores</h1>

      {status && (
        <div className="bg-gray-50 border border-gray-200 rounded p-4 mb-6">
          <p className="text-gray-600 mb-2">Estado actual:</p>
          <p
            className={`text-lg font-semibold ${
              status.twoFactorEnabled ? 'text-green-600' : 'text-red-600'
            }`}
          >
            {status.twoFactorEnabled ? '✅ Activado' : '❌ Desactivado'}
          </p>
        </div>
      )}

      {status?.twoFactorEnabled ? (
        <button
          onClick={handleDisable}
          disabled={loading}
          className="w-full bg-red-600 text-white py-2 rounded hover:bg-red-700 disabled:opacity-50"
        >
          {loading ? 'Desactivando...' : 'Desactivar 2FA'}
        </button>
      ) : (
        <button
          onClick={() => setIsModalOpen(true)}
          className="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700"
        >
          Activar 2FA
        </button>
      )}

      <Enable2FAModal
        token={token}
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSuccess={() => setStatus({ ...status, twoFactorEnabled: true })}
      />
    </div>
  );
}
```

---

## 📋 Checklist de Integración

- [ ] Crear `hooks/use2FA.ts`
- [ ] Crear `components/Enable2FAModal.tsx`
- [ ] Crear `components/LoginWith2FA.tsx`
- [ ] Crear `app/settings/2fa/page.tsx`
- [ ] Actualizar página de login para usar `LoginWith2FA`
- [ ] Agregar link a settings de 2FA en dashboard
- [ ] Probar flujo completo (activar + login):

```
1. Ir a settings → Activar 2FA
2. Escanear QR con app autenticadora
3. Ingresar código
4. Logout
5. Login con email + password
6. Ingresar código TOTP nuevo
7. ✅ Login completado
```

---

## 📊 Mapeo de Endpoints

| Frontend | Backend Endpoint | Método | Requiere JWT |
|----------|------------------|--------|--------------|
| generateQR() | `/auth/me/2fa` | POST | ✅ |
| enableTwoFactor() | `/auth/me/2fa` | PUT | ✅ |
| disableTwoFactor() | `/auth/me/2fa` | PUT | ✅ |
| getStatus() | `/auth/me/2fa` | GET | ✅ |
| verifyTOTPAndLogin() | `/auth/2fa/verify` | POST | ❌ |

---

**Todos los ejemplos están listos para copiar/pegar** ✅
