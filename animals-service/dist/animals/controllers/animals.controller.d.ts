import { AnimalsService } from '../services/animals.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';
export declare class AnimalsController {
    private readonly animalsService;
    constructor(animalsService: AnimalsService);
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
    })[]>;
    findOne(id: string): Promise<{
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
    create(dto: CreateAnimalDto, file?: Express.Multer.File): Promise<{
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
    update(id: string, dto: UpdateAnimalDto, file?: Express.Multer.File): Promise<{
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
    delete(id: string): Promise<{
        message: string;
        id: string;
    }>;
}
