import { UsersService } from '../services/users.service';
import { UsersDto } from '../dto/users.dto';
import { UpdateUsersDto } from '../dto/update-users.dto';
export declare class UsersController {
    private readonly userService;
    constructor(userService: UsersService);
    findByRefugio(refugioId: string): Promise<({
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
    } & {
        nombre: string;
        id_usuario: string;
        apellido_p: string;
        apellido_m: string;
        contrasena: string;
        email: string;
        activo: boolean;
        rol_id: string;
        refugio_id: string;
    })[]>;
    findOne(id: string): Promise<{
        rol: {
            nombre: string;
            refugio_id: string;
            id_roles: string;
        };
    } & {
        nombre: string;
        id_usuario: string;
        apellido_p: string;
        apellido_m: string;
        contrasena: string;
        email: string;
        activo: boolean;
        rol_id: string;
        refugio_id: string;
    }>;
    create(dto: UsersDto): Promise<{
        nombre: string;
        id_usuario: string;
        apellido_p: string;
        apellido_m: string;
        contrasena: string;
        email: string;
        activo: boolean;
        rol_id: string;
        refugio_id: string;
    }>;
    update(id: string, dto: UpdateUsersDto): Promise<{
        nombre: string;
        id_usuario: string;
        apellido_p: string;
        apellido_m: string;
        contrasena: string;
        email: string;
        activo: boolean;
        rol_id: string;
        refugio_id: string;
    }>;
    delete(id: string): Promise<{
        message: string;
        id: string;
    }>;
}
