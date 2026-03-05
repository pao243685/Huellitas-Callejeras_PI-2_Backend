"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const core_1 = require("@nestjs/core");
const shared_module_1 = require("./shared/shared.module");
const animals_module_1 = require("./animals/animals.module");
const movements_module_1 = require("./movements/movements.module");
const auth_module_1 = require("./auth/auth.module");
const jwt_guard_1 = require("./auth/guards/jwt.guard");
const roles_guard_1 = require("./auth/guards/roles.guard");
const refugio_module_1 = require("./refugio/refugio.module");
const users_module_1 = require("./users/users.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: '.env',
            }),
            shared_module_1.SharedModule,
            animals_module_1.AnimalsModule,
            movements_module_1.MovementsModule,
            auth_module_1.AuthModule,
            refugio_module_1.RefugioModule,
            users_module_1.UserModule,
        ],
        providers: [
            jwt_guard_1.JwtAuthGuard,
            {
                provide: core_1.APP_GUARD,
                useExisting: jwt_guard_1.JwtAuthGuard,
            },
            roles_guard_1.RolesGuard,
            {
                provide: core_1.APP_GUARD,
                useClass: roles_guard_1.RolesGuard,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map