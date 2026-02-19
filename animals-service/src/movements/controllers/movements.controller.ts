/* eslint-disable */
import { Controller, Get, Post, Patch, Delete, Param, Body, HttpCode } from '@nestjs/common';
import { MovementsService } from '../services/movements.service';
import { CreateMovementDto } from '../dto/create-movement.dto';
import { UpdateMovementDto } from '../dto/update-movement.dto';

@Controller('movements')
export class MovementsController {
  constructor(private readonly movementsService: MovementsService) {}

  @Get()
  async findAll() {
    return this.movementsService.findAll();
  }

  @Get('animal/:animal_id')
  async findByAnimal(@Param('animal_id') animalId: string) {
    return this.movementsService.findByAnimal(animalId);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.movementsService.findOne(id);
  }

  @Post()
  async create(@Body() dto: CreateMovementDto) {
    return this.movementsService.create(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateMovementDto) {
    return this.movementsService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.movementsService.delete(id);
  }
}