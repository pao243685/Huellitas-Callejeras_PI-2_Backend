/* eslint-disable */
import { Controller, Get, Post, Patch, Delete, Param, Body } from '@nestjs/common';
import { AnimalsService } from '../services/animals.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';

@Controller('animals')
export class AnimalsController {
  constructor(private readonly animalsService: AnimalsService) {}

  @Get()
  async findAll() {
    return this.animalsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.animalsService.findOne(id);
  }

  @Post()
  async create(@Body() dto: CreateAnimalDto) {
    return this.animalsService.create(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateAnimalDto) {
    return this.animalsService.update(id, dto);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.animalsService.delete(id);
  }
}
