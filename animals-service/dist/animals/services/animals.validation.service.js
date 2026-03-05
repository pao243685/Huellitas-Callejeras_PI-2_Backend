"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnimalsValidationService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
let AnimalsValidationService = class AnimalsValidationService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async validateRefugio(refugioId) {
        const refugio = await this.prisma.refugio.findUnique({
            where: { id_refugio: refugioId },
        });
        if (!refugio) {
            throw new common_1.NotFoundException(`Refugio ${refugioId} no existe`);
        }
    }
    async validateUsuario(usuarioId) {
        const usuario = await this.prisma.usuario.findUnique({
            where: { id_usuario: usuarioId },
        });
        if (!usuario) {
            throw new common_1.NotFoundException(`Usuario ${usuarioId} no existe`);
        }
    }
};
exports.AnimalsValidationService = AnimalsValidationService;
exports.AnimalsValidationService = AnimalsValidationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AnimalsValidationService);
//# sourceMappingURL=animals.validation.service.js.map