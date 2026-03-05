"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnimalsModule = void 0;
const common_1 = require("@nestjs/common");
const animals_controller_1 = require("./controllers/animals.controller");
const animals_service_1 = require("./services/animals.service");
const animals_validation_service_1 = require("./services/animals.validation.service");
const prisma_service_1 = require("../shared/prisma/prisma.service");
const multer_module_1 = require("@nestjs/platform-express/multer/multer.module");
let AnimalsModule = class AnimalsModule {
};
exports.AnimalsModule = AnimalsModule;
exports.AnimalsModule = AnimalsModule = __decorate([
    (0, common_1.Module)({
        imports: [multer_module_1.MulterModule.register({ dest: './uploads/animals' })],
        controllers: [animals_controller_1.AnimalsController],
        providers: [animals_service_1.AnimalsService, animals_validation_service_1.AnimalsValidationService, prisma_service_1.PrismaService],
        exports: [animals_service_1.AnimalsService],
    })
], AnimalsModule);
//# sourceMappingURL=animals.module.js.map