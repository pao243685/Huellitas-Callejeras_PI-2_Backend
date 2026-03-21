import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  HttpCode,
} from '@nestjs/common';
import { EtiquetasService } from '../services/etiquetas.service';
import { CreateEtiquetaDto } from '../dto/etiqueta.dto';
import { UpdateEtiquetaDto } from '../dto/update-etiqueta.dto';
import { AsignarEtiquetaDto } from '../dto/etiqueta-asignada.dto';
import { Roles } from '../../auth/decorators/roles.decorator';

@Controller('etiquetas')
export class EtiquetasController {
  constructor(private readonly etiquetasService: EtiquetasService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.etiquetasService.findByRefugio(refugioId);
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string) {
    return this.etiquetasService.findOne(id);
  }

  @Post()
  @Roles('admin', 'propietario')
  async create(@Body() dto: CreateEtiquetaDto) {
    return this.etiquetasService.create(dto);
  }

  @Patch(':id')
  @Roles('admin', 'propietario')
  async update(@Param('id') id: string, @Body() dto: UpdateEtiquetaDto) {
    return this.etiquetasService.update(id, dto);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.etiquetasService.delete(id);
  }

  @Post('animal/:animal_id')
  @Roles('admin', 'propietario')
  async asignar(
    @Param('animal_id') animalId: string,
    @Body() dto: AsignarEtiquetaDto,
  ) {
    return this.etiquetasService.asignarAAnimal(animalId, dto.etiqueta_id);
  }

  @Delete('animal/:animal_id/:etiqueta_id')
  @Roles('admin', 'propietario')
  @HttpCode(200)
  async quitar(
    @Param('animal_id') animalId: string,
    @Param('etiqueta_id') etiquetaId: string,
  ) {
    return this.etiquetasService.quitarDeAnimal(animalId, etiquetaId);
  }
}
