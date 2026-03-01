import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
} from '@nestjs/common';
import { UsersService } from '../services/users.service';
import { UsersDto } from '../dto/users.dto';
import { UpdateUsersDto } from '../dto/update-users.dto';
import { Roles } from '../../auth/decorators/roles.decorator';

@Controller('users')
export class UsersController {
  constructor(private readonly userService: UsersService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario')
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.userService.findByRefugio(refugioId);
  }

  @Get(':id')
  @Roles('admin', 'propietario')
  async findOne(@Param('id') id: string) {
    return this.userService.findOne(id);
  }

  @Post()
  @Roles('propietario')
  async create(@Body() dto: UsersDto) {
    return this.userService.create(dto);
  }

  @Patch(':id')
  @Roles('propietario')
  async update(@Param('id') id: string, @Body() dto: UpdateUsersDto) {
    return this.userService.update(id, dto);
  }

  @Delete(':id')
  @Roles('propietario')
  async delete(@Param('id') id: string) {
    return this.userService.delete(id);
  }
}
