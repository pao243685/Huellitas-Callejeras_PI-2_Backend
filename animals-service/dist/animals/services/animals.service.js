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
exports.AnimalsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
const animals_validation_service_1 = require("./animals.validation.service");
let AnimalsService = class AnimalsService {
    prisma;
    validation;
    constructor(prisma, validation) {
        this.prisma = prisma;
        this.validation = validation;
    }
    async findByRefugio(refugioId) {
        await this.validation.validateRefugio(refugioId);
        return this.prisma.animal.findMany({
            where: { refugio_id: refugioId },
            include: { refugio: true },
        });
    }
    async findOne(id) {
        const animal = await this.prisma.animal.findUnique({
            where: { id_animal: id },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Animal ${id} no encontrado`);
        }
        return animal;
    }
    async create(dto) {
        await this.validation.validateRefugio(dto.refugio_id);
        await this.validation.validateUsuario(dto.usuario_id);
        const animal = await this.prisma.animal.create({
            data: {
                nombre: dto.nombre,
                estado: dto.estado,
                especie: dto.especie,
                raza: dto.raza,
                edad: dto.edad,
                peso: dto.peso,
                sexo: dto.sexo,
                imagen: dto.imagen,
                tamano: dto.tamano,
                enfermedad_no_tratable: dto.enfermedad_no_tratable,
                discapacidad: dto.discapacidad,
                es_agresivo: dto.es_agresivo,
                lugar: dto.lugar,
                descripcion: dto.descripcion,
                refugio_id: dto.refugio_id,
                usuario_id: dto.usuario_id,
            },
        });
        return animal;
    }
    async update(id, dto) {
        const existing = await this.prisma.animal.findUnique({
            where: { id_animal: id },
        });
        if (!existing) {
            throw new common_1.NotFoundException(`Animal ${id} no encontrado`);
        }
        if (dto.refugio_id) {
            await this.validation.validateRefugio(dto.refugio_id);
        }
        if (dto.usuario_id) {
            await this.validation.validateUsuario(dto.usuario_id);
        }
        const animal = await this.prisma.animal.update({
            where: { id_animal: id },
            data: dto,
        });
        return animal;
    }
    async delete(id) {
        const animal = await this.prisma.animal.findUnique({
            where: { id_animal: id },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Animal ${id} no encontrado`);
        }
        await this.prisma.animal.delete({ where: { id_animal: id } });
        return { message: 'Animal eliminado', id };
    }
};
exports.AnimalsService = AnimalsService;
exports.AnimalsService = AnimalsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        animals_validation_service_1.AnimalsValidationService])
], AnimalsService);
//# sourceMappingURL=animals.service.js.map