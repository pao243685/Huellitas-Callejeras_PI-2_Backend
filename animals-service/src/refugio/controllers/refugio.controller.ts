import {
  Controller,
  Get,
  Patch,
  Delete,
  HttpCode,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { RefugioService } from '../services/refugio.service';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';
import type { UserResponse } from '../../auth/interfaces/jwt.interfaces';

@Controller('refugios')
export class RefugioController {
  constructor(private readonly refugioService: RefugioService) {}

  @Get('me')
  @Roles('admin', 'propietario', 'colaborador')
  async findMine(@CurrentUser() user: UserResponse) {
    return this.refugioService.findOne(user.refugio.id_refugio);
  }

  @Get(':id')
  @Roles('admin', 'propietario')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    if (user.rol.nombre !== 'admin' && user.refugio.id_refugio !== id) {
      const { ForbiddenException } = await import('@nestjs/common');
      throw new ForbiddenException('Solo puedes consultar tu propio refugio.');
    }
    return this.refugioService.findOne(id);
  }

  @Patch(':id')
  @Roles('propietario')
  @UseGuards(RefugioOwnershipGuard)
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateRefugioDto,
    @CurrentUser() user: UserResponse,
  ) {
    if (user.refugio.id_refugio !== id) {
      const { ForbiddenException } = await import('@nestjs/common');
      throw new ForbiddenException('Solo puedes editar tu propio refugio.');
    }
    return this.refugioService.update(id, dto);
  }

  @Delete(':id')
  @Roles('propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    if (user.refugio.id_refugio !== id) {
      const { ForbiddenException } = await import('@nestjs/common');
      throw new ForbiddenException('Solo puedes eliminar tu propio refugio.');
    }
    await this.refugioService.delete(id);
  }
}
