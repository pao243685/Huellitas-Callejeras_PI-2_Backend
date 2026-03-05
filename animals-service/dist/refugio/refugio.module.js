"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RefugioModule = void 0;
const common_1 = require("@nestjs/common");
const refugio_service_1 = require("./services/refugio.service");
const refugio_controller_1 = require("./controllers/refugio.controller");
const rol_service_1 = require("./services/rol.service");
const rol_controller_1 = require("./controllers/rol.controller");
const rol_validate_service_1 = require("./services/rol.validate.service");
let RefugioModule = class RefugioModule {
};
exports.RefugioModule = RefugioModule;
exports.RefugioModule = RefugioModule = __decorate([
    (0, common_1.Module)({
        providers: [refugio_service_1.RefugioService, rol_service_1.RolService, rol_validate_service_1.RolValidationService],
        controllers: [refugio_controller_1.RefugioController, rol_controller_1.RolController],
    })
], RefugioModule);
//# sourceMappingURL=refugio.module.js.map