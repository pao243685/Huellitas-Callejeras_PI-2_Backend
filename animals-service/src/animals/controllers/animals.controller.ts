import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { AnimalsService } from '../services/animals.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';

const storage = diskStorage({
  destination: './uploads/animals',
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${extname(file.originalname)}`);
  },
});

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
  @UseInterceptors(FileInterceptor('imagen', { storage }))
  async create(
    @Body() dto: CreateAnimalDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file) {
      dto.imagen = `uploads/animals/${file.filename}`;
    }
    return this.animalsService.create(dto);
  }

  @Patch(':id')
  @UseInterceptors(FileInterceptor('imagen', { storage }))
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateAnimalDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file) {
      dto.imagen = `uploads/animals/${file.filename}`;
    }
    return this.animalsService.update(id, dto);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.animalsService.delete(id);
  }
}
