"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateRolDto = void 0;
const mapped_types_1 = require("@nestjs/mapped-types");
const create_rol_dto_1 = require("./create-rol.dto");
class UpdateRolDto extends (0, mapped_types_1.PartialType)(create_rol_dto_1.CreateRolDto) {
}
exports.UpdateRolDto = UpdateRolDto;
//# sourceMappingURL=update-rol.dto.js.map