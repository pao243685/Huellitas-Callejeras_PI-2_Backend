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
exports.MovementsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
const movements_validation_service_1 = require("./movements.validation.service");
let MovementsService = class MovementsService {
    prisma;
    validation;
    constructor(prisma, validation) {
        this.prisma = prisma;
        this.validation = validation;
    }
    async findAll() {
        return this.prisma.movimiento.findMany({
            include: { animal: true },
            orderBy: { fecha_movimiento: 'desc' },
        });
    }
    async findOne(id) {
        const movimiento = await this.prisma.movimiento.findUnique({
            where: { id_movimiento: id },
            include: { animal: true },
        });
        if (!movimiento) {
            throw new common_1.NotFoundException(`Movimiento ${id} no encontrado`);
        }
        return movimiento;
    }
    async findByAnimal(animalId) {
        await this.validation.validateAnimal(animalId);
        return this.prisma.movimiento.findMany({
            where: { animal_id: animalId },
            include: { animal: true },
            orderBy: { fecha_movimiento: 'desc' },
        });
    }
    async create(dto) {
        await this.validation.validateAnimal(dto.animal_id);
        this.validation.validateMotivoByTipo(dto.tipo_movimiento, dto.motivo);
        return this.prisma.movimiento.create({
            data: {
                tipo_movimiento: dto.tipo_movimiento,
                motivo: dto.motivo,
                ...(dto.fecha_movimiento && {
                    fecha_movimiento: new Date(dto.fecha_movimiento),
                }),
                animal_id: dto.animal_id,
            },
            include: { animal: true },
        });
    }
    async update(id, dto) {
        const existing = await this.prisma.movimiento.findUnique({
            where: { id_movimiento: id },
        });
        if (!existing) {
            throw new common_1.NotFoundException(`Movimiento ${id} no encontrado`);
        }
        const tipoFinal = dto.tipo_movimiento ?? existing.tipo_movimiento;
        const motivoFinal = dto.motivo ?? existing.motivo;
        this.validation.validateMotivoByTipo(tipoFinal, motivoFinal);
        return this.prisma.movimiento.update({
            where: { id_movimiento: id },
            data: {
                ...(dto.tipo_movimiento && { tipo_movimiento: dto.tipo_movimiento }),
                ...(dto.motivo && { motivo: dto.motivo }),
                ...(dto.fecha_movimiento && {
                    fecha_movimiento: new Date(dto.fecha_movimiento),
                }),
            },
            include: { animal: true },
        });
    }
    async delete(id) {
        const movimiento = await this.prisma.movimiento.findUnique({
            where: { id_movimiento: id },
        });
        if (!movimiento) {
            throw new common_1.NotFoundException(`Movimiento ${id} no encontrado`);
        }
        await this.prisma.movimiento.delete({ where: { id_movimiento: id } });
        return { message: 'Movimiento eliminado', id };
    }
};
exports.MovementsService = MovementsService;
exports.MovementsService = MovementsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        movements_validation_service_1.MovementsValidationService])
], MovementsService);
//# sourceMappingURL=movements.service.js.map