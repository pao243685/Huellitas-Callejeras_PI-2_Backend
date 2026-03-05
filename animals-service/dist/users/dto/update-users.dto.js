"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateUsersDto = void 0;
const mapped_types_1 = require("@nestjs/mapped-types");
const users_dto_1 = require("./users.dto");
class UpdateUsersDto extends (0, mapped_types_1.PartialType)(users_dto_1.UsersDto) {
}
exports.UpdateUsersDto = UpdateUsersDto;
//# sourceMappingURL=update-users.dto.js.map