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
exports.RefugioService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
let RefugioService = class RefugioService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll() {
        return this.prisma.refugio.findMany();
    }
    async findOne(id) {
        const refugio = await this.prisma.refugio.findUnique({
            where: { id_refugio: id },
        });
        if (!refugio) {
            throw new common_1.NotFoundException(`Refugio ${id} no encontrado`);
        }
        return refugio;
    }
    async create(dto) {
        const refugio = await this.prisma.refugio.create({
            data: dto,
        });
        await this.prisma.rol.createMany({
            data: [
                { nombre: 'propietario', refugio_id: refugio.id_refugio },
                { nombre: 'admin', refugio_id: refugio.id_refugio },
                { nombre: 'colaborador', refugio_id: refugio.id_refugio },
            ],
        });
        return refugio;
    }
    async update(id, dto) {
        const existing = await this.prisma.refugio.findUnique({
            where: { id_refugio: id },
        });
        if (!existing) {
            throw new common_1.NotFoundException(`Refugio ${id} no encontrado`);
        }
        const refugio = await this.prisma.refugio.update({
            where: { id_refugio: id },
            data: dto,
        });
        return refugio;
    }
    async delete(id) {
        const animal = await this.prisma.refugio.findUnique({
            where: { id_refugio: id },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Refugio ${id} no encontrado`);
        }
        await this.prisma.refugio.delete({ where: { id_refugio: id } });
        return { message: 'Refugio eliminado', id };
    }
};
exports.RefugioService = RefugioService;
exports.RefugioService = RefugioService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], RefugioService);
//# sourceMappingURL=refugio.service.js.map