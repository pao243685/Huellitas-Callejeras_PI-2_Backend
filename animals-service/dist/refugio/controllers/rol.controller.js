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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RolController = void 0;
const common_1 = require("@nestjs/common");
const public_decorator_1 = require("../../auth/decorators/public.decorator");
const rol_service_1 = require("../services/rol.service");
const create_rol_dto_1 = require("../dto/create-rol.dto");
const update_rol_dto_1 = require("../dto/update-rol.dto");
let RolController = class RolController {
    rolService;
    constructor(rolService) {
        this.rolService = rolService;
    }
    async findByRefugio(refugioId) {
        return this.rolService.findByrefugio(refugioId);
    }
    async findOne(id) {
        return this.rolService.findOne(id);
    }
    async create(dto) {
        return this.rolService.create(dto);
    }
    async update(id, dto) {
        return this.rolService.update(id, dto);
    }
    async delete(id) {
        await this.rolService.delete(id);
    }
};
exports.RolController = RolController;
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Get)('refugio/:refugio_id'),
    __param(0, (0, common_1.Param)('refugio_id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RolController.prototype, "findByRefugio", null);
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RolController.prototype, "findOne", null);
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_rol_dto_1.CreateRolDto]),
    __metadata("design:returntype", Promise)
], RolController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_rol_dto_1.UpdateRolDto]),
    __metadata("design:returntype", Promise)
], RolController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.HttpCode)(204),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RolController.prototype, "delete", null);
exports.RolController = RolController = __decorate([
    (0, common_1.Controller)('roles'),
    __metadata("design:paramtypes", [rol_service_1.RolService])
], RolController);
//# sourceMappingURL=rol.controller.js.map