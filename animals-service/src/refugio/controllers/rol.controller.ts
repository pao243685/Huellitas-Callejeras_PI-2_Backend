import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  HttpCode,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { RolService } from '../services/rol.service';
import { CreateRolDto } from '../dto/create-rol.dto';
import { UpdateRolDto } from '../dto/update-rol.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';
import { RefugioBodyGuard } from '../../auth/guards/refugio-body.guard';

@Controller('roles')
export class RolController {
  constructor(private readonly rolService: RolService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  @UseGuards(RefugioOwnershipGuard)
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.rolService.findByrefugio(refugioId);
  }

  @Get(':id')
  @Roles('admin', 'propietario')
  async findOne(@Param('id') id: string) {
    return this.rolService.findOne(id);
  }

  @Post()
  @Roles('propietario')
  @UseGuards(RefugioBodyGuard)
  async create(@Body() dto: CreateRolDto) {
    return this.rolService.create(dto);
  }

  @Patch(':id')
  @Roles('propietario')
  async update(@Param('id') id: string, @Body() dto: UpdateRolDto) {
    return this.rolService.update(id, dto);
  }

  @Delete(':id')
  @Roles('propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.rolService.delete(id);
  }
}
