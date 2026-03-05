import { AuthService } from '../services/auth.service';
import { LoginDto } from '../dto/login.dto';
import { RegisterDto } from '../dto/register.dto';
import type { UserResponse } from '../interfaces/jwt.interfaces';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(registerDto: RegisterDto): Promise<{
        user: {
            rol: {
                nombre: string;
                id_roles: string;
            };
            refugio: {
                id_refugio: string;
                nombre: string;
            };
            nombre: string;
            id_usuario: string;
            apellido_p: string;
            apellido_m: string;
            email: string;
            activo: boolean;
        };
        access_token: string;
    }>;
    login(loginDto: LoginDto): Promise<{
        user: {
            rol: {
                nombre: string;
                refugio_id: string;
                id_roles: string;
            };
            refugio: {
                id_refugio: string;
                nombre: string;
                capacidad_max: number;
                estado: string;
                municipio: string;
                colonia: string;
                calle: string;
                num_exterior: number | null;
                num_interior: number | null;
            };
            nombre: string;
            id_usuario: string;
            apellido_p: string;
            apellido_m: string;
            email: string;
            activo: boolean;
            rol_id: string;
            refugio_id: string;
        };
        access_token: string;
    }>;
    getProfile(user: UserResponse): UserResponse;
}
