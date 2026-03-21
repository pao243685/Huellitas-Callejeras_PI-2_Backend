import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from '../services/users.service';
import { UsersDto } from '../dto/users.dto';
import { UpdateUsersDto } from '../dto/update-users.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';
import type { UserResponse } from '../../auth/interfaces/jwt.interfaces';

@Controller('users')
export class UsersController {
  constructor(private readonly userService: UsersService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario')
  @UseGuards(RefugioOwnershipGuard)
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.userService.findByRefugio(refugioId);
  }

  @Get(':id')
  @Roles('admin', 'propietario')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    return this.userService.findOne(id, user.refugio.id_refugio);
  }

  @Post()
  @Roles('propietario')
  async create(@Body() dto: UsersDto) {
    return this.userService.create(dto);
  }

  @Patch(':id')
  @Roles('propietario')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateUsersDto,
    @CurrentUser() user: UserResponse,
  ) {
    return this.userService.update(id, dto, user.refugio.id_refugio);
  }

  @Delete(':id')
  @Roles('propietario')
  async delete(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    return this.userService.delete(id, user.refugio.id_refugio);
  }
}
