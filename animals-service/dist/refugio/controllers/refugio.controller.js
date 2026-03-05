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
exports.RefugioController = void 0;
const common_1 = require("@nestjs/common");
const refugio_service_1 = require("../services/refugio.service");
const create_refugio_dto_1 = require("../dto/create-refugio.dto");
const update_refugio_dto_1 = require("../dto/update-refugio.dto");
const public_decorator_1 = require("../../auth/decorators/public.decorator");
const roles_decorator_1 = require("../../auth/decorators/roles.decorator");
let RefugioController = class RefugioController {
    refugioService;
    constructor(refugioService) {
        this.refugioService = refugioService;
    }
    async findAll() {
        return this.refugioService.findAll();
    }
    async findOne(id) {
        return this.refugioService.findOne(id);
    }
    async create(dto) {
        return this.refugioService.create(dto);
    }
    async update(id, dto) {
        return this.refugioService.update(id, dto);
    }
    async delete(id) {
        await this.refugioService.delete(id);
    }
};
exports.RefugioController = RefugioController;
__decorate([
    (0, common_1.Get)(),
    (0, roles_decorator_1.Roles)('admin', 'propietario', 'colaborador'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], RefugioController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, roles_decorator_1.Roles)('admin', 'propietario', 'colaborador'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RefugioController.prototype, "findOne", null);
__decorate([
    (0, public_decorator_1.Public)(),
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_refugio_dto_1.CreateRefugioDto]),
    __metadata("design:returntype", Promise)
], RefugioController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, roles_decorator_1.Roles)('propietario'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_refugio_dto_1.UpdateRefugioDto]),
    __metadata("design:returntype", Promise)
], RefugioController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, roles_decorator_1.Roles)('propietario'),
    (0, common_1.HttpCode)(204),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RefugioController.prototype, "delete", null);
exports.RefugioController = RefugioController = __decorate([
    (0, common_1.Controller)('refugios'),
    __metadata("design:paramtypes", [refugio_service_1.RefugioService])
], RefugioController);
//# sourceMappingURL=refugio.controller.js.map