import { PartialType } from '@nestjs/mapped-types';
import { UsersDto } from './users.dto';

export class UpdateUsersDto extends PartialType(UsersDto) {}
