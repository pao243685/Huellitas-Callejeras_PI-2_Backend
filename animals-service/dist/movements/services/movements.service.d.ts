import { PrismaService } from '../../shared/prisma/prisma.service';
import { MovementsValidationService } from './movements.validation.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { UpdateMovementDto } from '../dto/update-movement.dto';
export declare class MovementsService {
    private readonly prisma;
    private readonly validation;
    constructor(prisma: PrismaService, validation: MovementsValidationService);
    findAll(): Promise<({
        animal: {
            nombre: string;
            estado: import(".prisma/client").$Enums.EstadoAnimal;
            refugio_id: string;
            especie: string;
            raza: string;
            edad: number;
            peso: import("@prisma/client/runtime/library").Decimal;
            sexo: import(".prisma/client").$Enums.SexoAnimal;
            imagen: string | null;
            tamano: import(".prisma/client").$Enums.TamanoLista;
            enfermedad_no_tratable: boolean;
            discapacidad: boolean;
            es_agresivo: boolean;
            lugar: string;
            descripcion: string;
            usuario_id: string;
            id_animal: string;
        };
    } & {
        tipo_movimiento: import(".prisma/client").$Enums.MovimientoTipo;
        motivo: import(".prisma/client").$Enums.MovimientoMotivo;
        fecha_movimiento: Date;
        animal_id: string;
        id_movimiento: string;
    })[]>;
    findOne(id: string): Promise<{
        animal: {
            nombre: string;
            estado: import(".prisma/client").$Enums.EstadoAnimal;
            refugio_id: string;
            especie: string;
            raza: string;
            edad: number;
            peso: import("@prisma/client/runtime/library").Decimal;
            sexo: import(".prisma/client").$Enums.SexoAnimal;
            imagen: string | null;
            tamano: import(".prisma/client").$Enums.TamanoLista;
            enfermedad_no_tratable: boolean;
            discapacidad: boolean;
            es_agresivo: boolean;
            lugar: string;
            descripcion: string;
            usuario_id: string;
            id_animal: string;
        };
    } & {
        tipo_movimiento: import(".prisma/client").$Enums.MovimientoTipo;
        motivo: import(".prisma/client").$Enums.MovimientoMotivo;
        fecha_movimiento: Date;
        animal_id: string;
        id_movimiento: string;
    }>;
    findByAnimal(animalId: string): Promise<({
        animal: {
            nombre: string;
            estado: import(".prisma/client").$Enums.EstadoAnimal;
            refugio_id: string;
            especie: string;
            raza: string;
            edad: number;
            peso: import("@prisma/client/runtime/library").Decimal;
            sexo: import(".prisma/client").$Enums.SexoAnimal;
            imagen: string | null;
            tamano: import(".prisma/client").$Enums.TamanoLista;
            enfermedad_no_tratable: boolean;
            discapacidad: boolean;
            es_agresivo: boolean;
            lugar: string;
            descripcion: string;
            usuario_id: string;
            id_animal: string;
        };
    } & {
        tipo_movimiento: import(".prisma/client").$Enums.MovimientoTipo;
        motivo: import(".prisma/client").$Enums.MovimientoMotivo;
        fecha_movimiento: Date;
        animal_id: string;
        id_movimiento: string;
    })[]>;
    create(dto: CreateMovementDto): Promise<{
        animal: {
            nombre: string;
            estado: import(".prisma/client").$Enums.EstadoAnimal;
            refugio_id: string;
            especie: string;
            raza: string;
            edad: number;
            peso: import("@prisma/client/runtime/library").Decimal;
            sexo: import(".prisma/client").$Enums.SexoAnimal;
            imagen: string | null;
            tamano: import(".prisma/client").$Enums.TamanoLista;
            enfermedad_no_tratable: boolean;
            discapacidad: boolean;
            es_agresivo: boolean;
            lugar: string;
            descripcion: string;
            usuario_id: string;
            id_animal: string;
        };
    } & {
        tipo_movimiento: import(".prisma/client").$Enums.MovimientoTipo;
        motivo: import(".prisma/client").$Enums.MovimientoMotivo;
        fecha_movimiento: Date;
        animal_id: string;
        id_movimiento: string;
    }>;
    update(id: string, dto: UpdateMovementDto): Promise<{
        animal: {
            nombre: string;
            estado: import(".prisma/client").$Enums.EstadoAnimal;
            refugio_id: string;
            especie: string;
            raza: string;
            edad: number;
            peso: import("@prisma/client/runtime/library").Decimal;
            sexo: import(".prisma/client").$Enums.SexoAnimal;
            imagen: string | null;
            tamano: import(".prisma/client").$Enums.TamanoLista;
            enfermedad_no_tratable: boolean;
            discapacidad: boolean;
            es_agresivo: boolean;
            lugar: string;
            descripcion: string;
            usuario_id: string;
            id_animal: string;
        };
    } & {
        tipo_movimiento: import(".prisma/client").$Enums.MovimientoTipo;
        motivo: import(".prisma/client").$Enums.MovimientoMotivo;
        fecha_movimiento: Date;
        animal_id: string;
        id_movimiento: string;
    }>;
    delete(id: string): Promise<{
        message: string;
        id: string;
    }>;
}
