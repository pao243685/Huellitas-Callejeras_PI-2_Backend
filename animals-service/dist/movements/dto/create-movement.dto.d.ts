import { MovimientoTipo, MovimientoMotivo } from '@prisma/client';
export declare class CreateMovementDto {
    tipo_movimiento: MovimientoTipo;
    motivo: MovimientoMotivo;
    fecha_movimiento?: string;
    animal_id: string;
}
