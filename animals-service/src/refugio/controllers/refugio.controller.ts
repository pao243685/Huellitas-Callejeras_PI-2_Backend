import {
  Controller,
  Get,
  Patch,
  Delete,
  HttpCode,
  Param,
  Body,
} from '@nestjs/common';
import { RefugioService } from '../services/refugio.service';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';
import { Roles } from '../../auth/decorators/roles.decorator';

@Controller('refugios')
export class RefugioController {
  constructor(private readonly refugioService: RefugioService) {}

  @Get()
  @Roles('admin', 'propietario', 'colaborador')
  async findAll() {
    return this.refugioService.findAll();
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string) {
    return this.refugioService.findOne(id);
  }

  @Patch(':id')
  @Roles('propietario')
  async update(@Param('id') id: string, @Body() dto: UpdateRefugioDto) {
    return this.refugioService.update(id, dto);
  }

  @Delete(':id')
  @Roles('propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.refugioService.delete(id);
  }
}
