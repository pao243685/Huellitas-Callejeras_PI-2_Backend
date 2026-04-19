import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  HttpCode,
  BadRequestException,
} from '@nestjs/common';
import { MovementsService } from '../services/movements.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { UserResponse } from '../../auth/interfaces/jwt.interfaces';

function assertNotFutureDate(fecha: string | undefined, campo: string): void {
  if (!fecha) return;
  const parsed = new Date(fecha);
  if (isNaN(parsed.getTime())) {
    throw new BadRequestException(
      `El campo "${campo}" no es una fecha válida.`,
    );
  }
  if (parsed > new Date()) {
    throw new BadRequestException(
      `El campo "${campo}" no puede ser una fecha futura. ` +
        `Valor recibido: ${parsed.toISOString()}.`,
    );
  }
}

@Controller('movements')
export class MovementsController {
  constructor(private readonly movementsService: MovementsService) {}

  @Get()
  @Roles('admin', 'propietario', 'colaborador')
  async getAll(@CurrentUser() user: UserResponse) {
    return this.movementsService.findAll(user.refugio.id_refugio);
  }

  @Get('animal/:animal_id')
  @Roles('admin', 'propietario', 'colaborador')
  async findByAnimal(
    @Param('animal_id') animalId: string,
    @CurrentUser() user: UserResponse,
  ) {
    return this.movementsService.findByAnimal(
      animalId,
      user.refugio.id_refugio,
    );
  }

  @Post()
  @Roles('admin', 'propietario')
  async create(
    @Body() dto: CreateMovementDto,
    @CurrentUser() user: UserResponse,
  ) {
    assertNotFutureDate(dto.fecha_movimiento, 'fecha_movimiento');
    return this.movementsService.create(dto, user.refugio.id_refugio);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    await this.movementsService.delete(id, user.refugio.id_refugio);
  }
}
