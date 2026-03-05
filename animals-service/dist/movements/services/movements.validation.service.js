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
exports.MovementsValidationService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
const client_1 = require("@prisma/client");
let MovementsValidationService = class MovementsValidationService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async validateAnimal(animalId) {
        const animal = await this.prisma.animal.findUnique({
            where: { id_animal: animalId },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Animal ${animalId} no existe`);
        }
        return animal;
    }
    validateMotivoByTipo(tipo, motivo) {
        const motivosEntrada = [
            client_1.MovimientoMotivo.rescate,
            client_1.MovimientoMotivo.retorno,
        ];
        const motivosSalida = [
            client_1.MovimientoMotivo.adopcion,
            client_1.MovimientoMotivo.defuncion,
            client_1.MovimientoMotivo.extravio,
        ];
        if (tipo === client_1.MovimientoTipo.entrada && !motivosEntrada.includes(motivo)) {
            throw new common_1.BadRequestException(`Para tipo "entrada" el motivo debe ser: rescate o retorno`);
        }
        if (tipo === client_1.MovimientoTipo.salida && !motivosSalida.includes(motivo)) {
            throw new common_1.BadRequestException(`Para tipo "salida" el motivo debe ser: adopcion, defuncion o extravio`);
        }
    }
};
exports.MovementsValidationService = MovementsValidationService;
exports.MovementsValidationService = MovementsValidationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MovementsValidationService);
//# sourceMappingURL=movements.validation.service.js.map