/* eslint-disable */
import { Controller, Get, Post, Patch, Delete, Param, Body, HttpCode } from '@nestjs/common';
import { MovementsService } from '../services/movements.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { UpdateMovementDto } from '../dto/update-movement.dto';
import { Roles } from '../../auth/decorators/roles.decorator';

@Controller('movements')
export class MovementsController {
  constructor(private readonly movementsService: MovementsService) {}


  @Get('animal/:animal_id')
  @Roles('admin', 'propietario', 'colaborador')
  async findByAnimal(@Param('animal_id') animalId: string) {
    return this.movementsService.findByAnimal(animalId);
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string) {
    return this.movementsService.findOne(id);
  }

  @Post()
  @Roles('admin', 'propietario')
  async create(@Body() dto: CreateMovementDto) {
    return this.movementsService.create(dto);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.movementsService.delete(id);
  }
}