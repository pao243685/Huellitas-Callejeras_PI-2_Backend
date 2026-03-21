import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  HttpCode,
  UseGuards,
} from '@nestjs/common';
import { EtiquetasService } from '../services/etiquetas.service';
import { CreateEtiquetaDto } from '../dto/etiqueta.dto';
import { UpdateEtiquetaDto } from '../dto/update-etiqueta.dto';
import { AsignarEtiquetaDto } from '../dto/etiqueta-asignada.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';
import type { UserResponse } from '../../auth/interfaces/jwt.interfaces';

@Controller('etiquetas')
export class EtiquetasController {
  constructor(private readonly etiquetasService: EtiquetasService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  @UseGuards(RefugioOwnershipGuard)
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.etiquetasService.findByRefugio(refugioId);
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    return this.etiquetasService.findOne(id, user.refugio.id_refugio);
  }

  @Post()
  @Roles('admin', 'propietario')
  async create(@Body() dto: CreateEtiquetaDto) {
    return this.etiquetasService.create(dto);
  }

  @Patch(':id')
  @Roles('admin', 'propietario')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateEtiquetaDto,
    @CurrentUser() user: UserResponse,
  ) {
    return this.etiquetasService.update(id, dto, user.refugio.id_refugio);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    await this.etiquetasService.delete(id, user.refugio.id_refugio);
  }

  @Post('animal/:animal_id')
  @Roles('admin', 'propietario')
  async asignar(
    @Param('animal_id') animalId: string,
    @Body() dto: AsignarEtiquetaDto,
    @CurrentUser() user: UserResponse,
  ) {
    return this.etiquetasService.asignarAAnimal(
      animalId,
      dto.etiqueta_id,
      user.refugio.id_refugio,
    );
  }

  @Delete('animal/:animal_id/:etiqueta_id')
  @Roles('admin', 'propietario')
  @HttpCode(200)
  async quitar(
    @Param('animal_id') animalId: string,
    @Param('etiqueta_id') etiquetaId: string,
    @CurrentUser() user: UserResponse,
  ) {
    return this.etiquetasService.quitarDeAnimal(
      animalId,
      etiquetaId,
      user.refugio.id_refugio,
    );
  }
}
