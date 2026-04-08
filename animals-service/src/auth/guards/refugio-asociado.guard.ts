import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { UserResponse } from '../interfaces/jwt.interfaces';

@Injectable()
export class RefugioOwnershipGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{
      user: UserResponse;
      params: Record<string, string>;
      body: Record<string, unknown>;
    }>();

    const user = request.user;
    
    // Buscar refugio_id en parámetros (para GET, DELETE, etc.)
    let refugioId: string | undefined = request.params['refugio_id'];
    
    // Si no está en parámetros, buscar en body (para POST, PATCH, etc.)
    if (!refugioId && request.body?.refugio_id) {
      refugioId = request.body.refugio_id as string;
    }

    if (!refugioId) return true;

    // Permitir si es admin
    if (user?.rol?.nombre === 'admin') {
      return true;
    }

    // Para propietario, verificar que el refugio_id coincida con su refugio
    if (user?.refugio?.id_refugio !== refugioId) {
      throw new ForbiddenException(
        'No puedes acceder a datos de otro refugio. Tu refugio: ' + 
        user?.refugio?.id_refugio + ', solicitado: ' + refugioId,
      );
    }

    return true;
  }
}
