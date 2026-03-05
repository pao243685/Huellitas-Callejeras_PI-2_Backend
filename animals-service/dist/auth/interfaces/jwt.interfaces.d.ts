export interface JwtPayload {
    sub: string;
    email: string;
    rol: string;
    refugio: string;
}
export interface UserResponse {
    id_usuario: string;
    nombre: string;
    apellido_p: string;
    apellido_m: string;
    email: string;
    activo: boolean;
    rol: {
        id_roles: string;
        nombre: string;
    };
    refugio: {
        id_refugio: string;
        nombre: string;
    };
}
