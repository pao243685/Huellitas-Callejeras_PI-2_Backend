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
import { RefugioService } from '../services/refugio.service';
import { CreateRefugioDto } from '../dto/create-refugio.dto';
import { UpdateRefugioDto } from '../dto/update-refugio.dto';
import { Public } from '../../auth/decorators/public.decorator';

@Controller('refugios')
export class RefugioController {
  constructor(private readonly refugioService: RefugioService) {}

  @Get()
  async findAll() {
    return this.refugioService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.refugioService.findOne(id);
  }

  @Public()
  @Post()
  async create(@Body() dto: CreateRefugioDto) {
    return this.refugioService.create(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateRefugioDto) {
    return this.refugioService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  async delete(@Param('id') id: string) {
    await this.refugioService.delete(id);
  }
}
