import { RolService } from '../services/rol.service';
import { CreateRolDto } from '../dto/create-rol.dto';
import { UpdateRolDto } from '../dto/update-rol.dto';
export declare class RolController {
    private readonly rolService;
    constructor(rolService: RolService);
    findByRefugio(refugioId: string): Promise<({
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
        refugio_id: string;
        id_roles: string;
    })[]>;
    findOne(id: string): Promise<{
        nombre: string;
        refugio_id: string;
        id_roles: string;
    }>;
    create(dto: CreateRolDto): Promise<{
        nombre: string;
        refugio_id: string;
        id_roles: string;
    }>;
    update(id: string, dto: UpdateRolDto): Promise<{
        nombre: string;
        refugio_id: string;
        id_roles: string;
    }>;
    delete(id: string): Promise<void>;
}
