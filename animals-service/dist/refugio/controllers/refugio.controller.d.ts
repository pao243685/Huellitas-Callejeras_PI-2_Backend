import { RefugioService } from '../services/refugio.service';
import { CreateRefugioDto } from '../dto/create-refugio.dto';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';
export declare class RefugioController {
    private readonly refugioService;
    constructor(refugioService: RefugioService);
    findAll(): Promise<{
        id_refugio: string;
        nombre: string;
        capacidad_max: number;
        estado: string;
        municipio: string;
        colonia: string;
        calle: string;
        num_exterior: number | null;
        num_interior: number | null;
    }[]>;
    findOne(id: string): Promise<{
        id_refugio: string;
        nombre: string;
        capacidad_max: number;
        estado: string;
        municipio: string;
        colonia: string;
        calle: string;
        num_exterior: number | null;
        num_interior: number | null;
    }>;
    create(dto: CreateRefugioDto): Promise<{
        id_refugio: string;
        nombre: string;
        capacidad_max: number;
        estado: string;
        municipio: string;
        colonia: string;
        calle: string;
        num_exterior: number | null;
        num_interior: number | null;
    }>;
    update(id: string, dto: UpdateRefugioDto): Promise<{
        id_refugio: string;
        nombre: string;
        capacidad_max: number;
        estado: string;
        municipio: string;
        colonia: string;
        calle: string;
        num_exterior: number | null;
        num_interior: number | null;
    }>;
    delete(id: string): Promise<void>;
}
