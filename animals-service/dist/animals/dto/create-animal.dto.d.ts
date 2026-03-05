import { TamanoLista, SexoAnimal, EstadoAnimal } from '@prisma/client';
export declare class CreateAnimalDto {
    nombre: string;
    estado: EstadoAnimal;
    especie: string;
    raza: string;
    edad: number;
    peso: any;
    sexo: SexoAnimal;
    imagen?: string;
    tamano: TamanoLista;
    enfermedad_no_tratable: boolean;
    discapacidad: boolean;
    es_agresivo: boolean;
    lugar: string;
    descripcion: string;
    refugio_id: string;
    usuario_id: string;
}
