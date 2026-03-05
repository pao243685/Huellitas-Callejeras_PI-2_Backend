"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateRefugioDto = void 0;
const mapped_types_1 = require("@nestjs/mapped-types");
const create_refugio_dto_1 = require("./create-refugio.dto");
class UpdateRefugioDto extends (0, mapped_types_1.PartialType)(create_refugio_dto_1.CreateRefugioDto) {
}
exports.UpdateRefugioDto = UpdateRefugioDto;
//# sourceMappingURL=update-refugio.dto.js.map