import {
  Controller,
  Post,
  Body,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AnimalsSpService } from '../services/animals.sp.service';
import { RegistrarAnimalSpDto } from '../dto/registrar-animal-sp.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';

@ApiTags('Animals')
@ApiBearerAuth()
@Controller('animals')
export class AnimalsSpController {
  constructor(private readonly animalsSpService: AnimalsSpService) {}

  @Post('registrar')
  @Roles('admin', 'propietario')
  @UseGuards(RefugioOwnershipGuard)
  @ApiOperation({
    summary: 'Registrar animal completo (SP)',
    description:
      'Ejecuta `sp_registrar_animal_completo`. Crea el expediente del animal, ' +
      'su imagen inicial (opcional) y su primer movimiento de entrada en una sola transacción atómica.',
  })
  @ApiResponse({
    status: 201,
    description: 'Animal registrado exitosamente',
    schema: {
      example: { id_animal_creado: 'b1c2d3e4-0000-0000-0000-000000000099' },
    },
  })
  @ApiResponse({ status: 400, description: 'Datos inválidos o refugio sin capacidad' })
  @ApiResponse({ status: 401, description: 'Token JWT no válido o ausente' })
  @ApiResponse({ status: 403, description: 'Sin permisos suficientes' })
  async registrarAnimal(@Body() dto: RegistrarAnimalSpDto) {
    return this.animalsSpService.registrarAnimalCompleto(dto);
  }
}