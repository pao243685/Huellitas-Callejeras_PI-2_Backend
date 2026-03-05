import { PrismaService } from '../../shared/prisma/prisma.service';
export declare class AnimalsValidationService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    validateRefugio(refugioId: string): Promise<void>;
    validateUsuario(usuarioId: string): Promise<void>;
}
