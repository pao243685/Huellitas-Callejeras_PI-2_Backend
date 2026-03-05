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
exports.CreateAnimalDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class CreateAnimalDto {
    nombre;
    estado;
    especie;
    raza;
    edad;
    peso;
    sexo;
    imagen;
    tamano;
    enfermedad_no_tratable;
    discapacidad;
    es_agresivo;
    lugar;
    descripcion;
    refugio_id;
    usuario_id;
}
exports.CreateAnimalDto = CreateAnimalDto;
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "nombre", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.EstadoAnimal),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "estado", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "especie", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "raza", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateAnimalDto.prototype, "edad", void 0);
__decorate([
    (0, class_validator_1.IsDecimal)(),
    __metadata("design:type", Object)
], CreateAnimalDto.prototype, "peso", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.SexoAnimal),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "sexo", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "imagen", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.TamanoLista),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "tamano", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateAnimalDto.prototype, "enfermedad_no_tratable", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateAnimalDto.prototype, "discapacidad", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateAnimalDto.prototype, "es_agresivo", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "lugar", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "descripcion", void 0);
__decorate([
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "refugio_id", void 0);
__decorate([
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateAnimalDto.prototype, "usuario_id", void 0);
//# sourceMappingURL=create-animal.dto.js.map