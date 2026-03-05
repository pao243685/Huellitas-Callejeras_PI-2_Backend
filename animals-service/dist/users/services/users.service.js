"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../shared/prisma/prisma.service");
const usuario_validation_service_1 = require("./usuario.validation.service");
const bcrypt = __importStar(require("bcrypt"));
let UsersService = class UsersService {
    prisma;
    validation;
    constructor(prisma, validation) {
        this.prisma = prisma;
        this.validation = validation;
    }
    async findByRefugio(refugioId) {
        await this.validation.validateRefugio(refugioId);
        return this.prisma.usuario.findMany({
            where: { refugio_id: refugioId },
            include: {
                refugio: true,
                rol: true,
            },
        });
    }
    async findOne(id) {
        const user = await this.prisma.usuario.findUnique({
            where: { id_usuario: id },
            include: { rol: true },
        });
        if (!user) {
            throw new common_1.NotFoundException(`Usuario ${id} no encontrado`);
        }
        return user;
    }
    async create(dto) {
        await this.validation.validateRefugio(dto.refugio_id);
        const hashedPassword = await bcrypt.hash(dto.contrasena, 10);
        const user = await this.prisma.usuario.create({
            data: {
                nombre: dto.nombre,
                apellido_p: dto.apellido_p,
                apellido_m: dto.apellido_m,
                email: dto.email,
                contrasena: hashedPassword,
                activo: dto.activo,
                rol_id: dto.rol_id,
                refugio_id: dto.refugio_id,
            },
        });
        return user;
    }
    async update(id, dto) {
        const existing = await this.prisma.usuario.findUnique({
            where: { id_usuario: id },
        });
        if (!existing)
            throw new common_1.NotFoundException(`Usuario ${id} no encontrado`);
        const data = { ...dto };
        if (dto.contrasena) {
            data.contrasena = await bcrypt.hash(dto.contrasena, 10);
        }
        else {
            delete data.contrasena;
        }
        return this.prisma.usuario.update({
            where: { id_usuario: id },
            data,
        });
    }
    async delete(id) {
        const animal = await this.prisma.usuario.findUnique({
            where: { id_usuario: id },
        });
        if (!animal) {
            throw new common_1.NotFoundException(`Usuario ${id} no encontrado`);
        }
        await this.prisma.usuario.delete({ where: { id_usuario: id } });
        return { message: 'Usuario eliminado', id };
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        usuario_validation_service_1.UsersValidationService])
], UsersService);
//# sourceMappingURL=users.service.js.map