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
exports.RolService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
const rol_validate_service_1 = require("./rol.validate.service");
let RolService = class RolService {
    prisma;
    validation;
    constructor(prisma, validation) {
        this.prisma = prisma;
        this.validation = validation;
    }
    async findByrefugio(refugioId) {
        await this.validation.validateRefugio(refugioId);
        return this.prisma.rol.findMany({
            where: { refugio_id: refugioId },
            include: { refugio: true },
        });
    }
    async findOne(id) {
        const refugio = await this.prisma.rol.findUnique({
            where: { id_roles: id },
        });
        if (!refugio) {
            throw new common_1.NotFoundException(`Rol ${id} no encontrado`);
        }
        return refugio;
    }
    async create(dto) {
        const refugio = await this.prisma.rol.create({
            data: dto,
        });
        return refugio;
    }
    async update(id, dto) {
        const existing = await this.prisma.rol.findUnique({
            where: { id_roles: id },
        });
        if (!existing) {
            throw new common_1.NotFoundException(`Rol ${id} no encontrado`);
        }
        const refugio = await this.prisma.rol.update({
            where: { id_roles: id },
            data: dto,
        });
        return refugio;
    }
    async delete(id) {
        const animal = await this.prisma.rol.findUnique({
            where: { id_roles: id },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Rol ${id} no encontrado`);
        }
        await this.prisma.rol.delete({ where: { id_roles: id } });
        return { message: 'Rol   eliminado', id };
    }
};
exports.RolService = RolService;
exports.RolService = RolService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        rol_validate_service_1.RolValidationService])
], RolService);
//# sourceMappingURL=rol.service.js.map