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
exports.AnimalsController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const multer_1 = require("multer");
const path_1 = require("path");
const animals_service_1 = require("../services/animals.service");
const create_animal_dto_1 = require("../dto/create-animal.dto");
const update_animal_dto_1 = require("../dto/update-animal.dto");
const roles_decorator_1 = require("../../auth/decorators/roles.decorator");
const storage = (0, multer_1.diskStorage)({
    destination: './uploads/animals',
    filename: (req, file, cb) => {
        const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        cb(null, `${unique}${(0, path_1.extname)(file.originalname)}`);
    },
});
let AnimalsController = class AnimalsController {
    animalsService;
    constructor(animalsService) {
        this.animalsService = animalsService;
    }
    async findByRefugio(refugioId) {
        return this.animalsService.findByRefugio(refugioId);
    }
    async findOne(id) {
        return this.animalsService.findOne(id);
    }
    async create(dto, file) {
        if (file) {
            dto.imagen = `uploads/animals/${file.filename}`;
        }
        return this.animalsService.create(dto);
    }
    async update(id, dto, file) {
        if (file) {
            dto.imagen = `uploads/animals/${file.filename}`;
        }
        return this.animalsService.update(id, dto);
    }
    async delete(id) {
        return this.animalsService.delete(id);
    }
};
exports.AnimalsController = AnimalsController;
__decorate([
    (0, common_1.Get)('refugio/:refugio_id'),
    (0, roles_decorator_1.Roles)('admin', 'propietario', 'colaborador'),
    __param(0, (0, common_1.Param)('refugio_id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AnimalsController.prototype, "findByRefugio", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, roles_decorator_1.Roles)('admin', 'propietario', 'colaborador'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AnimalsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(),
    (0, roles_decorator_1.Roles)('admin', 'propietario'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('imagen', { storage })),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.UploadedFile)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_animal_dto_1.CreateAnimalDto, Object]),
    __metadata("design:returntype", Promise)
], AnimalsController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, roles_decorator_1.Roles)('admin', 'propietario'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('imagen', { storage })),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.UploadedFile)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_animal_dto_1.UpdateAnimalDto, Object]),
    __metadata("design:returntype", Promise)
], AnimalsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, roles_decorator_1.Roles)('admin', 'propietario'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AnimalsController.prototype, "delete", null);
exports.AnimalsController = AnimalsController = __decorate([
    (0, common_1.Controller)('animals'),
    __metadata("design:paramtypes", [animals_service_1.AnimalsService])
], AnimalsController);
//# sourceMappingURL=animals.controller.js.map