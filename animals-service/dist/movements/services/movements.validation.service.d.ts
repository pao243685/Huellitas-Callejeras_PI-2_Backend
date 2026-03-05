import { PrismaService } from '../../shared/prisma/prisma.service';
import { MovimientoTipo, MovimientoMotivo } from '@prisma/client';
export declare class MovementsValidationService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    validateAnimal(animalId: string): Promise<{
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
    }>;
    validateMotivoByTipo(tipo: MovimientoTipo, motivo: MovimientoMotivo): void;
}
