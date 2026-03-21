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
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { AnimalsService } from '../services/animals.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';
import { Roles } from '../../auth/decorators/roles.decorator';

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

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  async findByRefugio(
    @Param('refugio_id') refugioId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '10',
  ) {
    return this.animalsService.findByRefugio(refugioId, +page, +limit);
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string) {
    return this.animalsService.findOne(id);
  }

  @Post()
  @Roles('admin', 'propietario')
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
  @Roles('admin', 'propietario')
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

  @Delete('imagen/:imagenId')
  @Roles('admin', 'propietario')
  async deleteImagen(@Param('imagenId') imagenId: string) {
    return this.animalsService.deleteImagen(imagenId);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  async delete(@Param('id') id: string) {
    return this.animalsService.delete(id);
  }
}
