import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  HttpCode,
  Param,
  Body,
} from '@nestjs/common';
import { Public } from '../../auth/decorators/public.decorator';
import { RolService } from '../services/rol.service';
import { CreateRolDto } from '../dto/create-rol.dto';
import { UpdateRolDto } from '../dto/update-rol.dto';

@Controller('roles')
export class RolController {
  constructor(private readonly rolService: RolService) {}

  @Get()
  async findAll() {
    return this.rolService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.rolService.findOne(id);
  }

  @Public()
  @Post()
  async create(@Body() dto: CreateRolDto) {
    return this.rolService.create(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateRolDto) {
    return this.rolService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.rolService.delete(id);
  }
}
