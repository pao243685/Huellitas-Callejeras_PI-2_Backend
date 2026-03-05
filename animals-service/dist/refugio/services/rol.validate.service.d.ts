import { PrismaService } from '../../shared/prisma/prisma.service';
export declare class RolValidationService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    validateRefugio(refugioId: string): Promise<void>;
}
