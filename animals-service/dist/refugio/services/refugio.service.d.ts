import { PrismaService } from 'src/shared/prisma/prisma.service';
import { CreateRefugioDto } from '../dto/create-refugio.dto';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';
export declare class RefugioService {
    private readonly prisma;
    constructor(prisma: PrismaService);
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
    delete(id: string): Promise<{
        message: string;
        id: string;
    }>;
}
