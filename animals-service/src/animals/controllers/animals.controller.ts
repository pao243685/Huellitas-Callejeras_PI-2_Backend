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
  UseGuards,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { AnimalsService } from '../services/animals.service';
import {
  AnimalsSpService,
  type AnimalConRelaciones,
} from '../services/animals.sp.service';
import { CreateAnimalDto } from '../dto/create-animal.dto';
import { UpdateAnimalDto } from '../dto/update-animal.dto';
import { RegistrarAnimalSpDto } from '../dto/registrar-animal-sp.dto';
import { Roles } from '../../auth/decorators/roles.decorator';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';
import type { UserResponse } from '../../auth/interfaces/jwt.interfaces';

const storage = diskStorage({
  destination: './uploads/animals',
  filename: (req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${extname(file.originalname)}`);
  },
});

@Controller('animals')
export class AnimalsController {
  constructor(
    private readonly animalsService: AnimalsService,
    private readonly animalsSpService: AnimalsSpService,
  ) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  @UseGuards(RefugioOwnershipGuard)
  async findByRefugio(
    @Param('refugio_id') refugioId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '10',
  ) {
    return this.animalsService.findByRefugio(refugioId, +page, +limit);
  }

  @Get(':id')
  @Roles('admin', 'propietario', 'colaborador')
  async findOne(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    return this.animalsService.findOne(id, user.refugio.id_refugio);
  }

  @Post()
  @Roles('admin', 'propietario')
  @UseInterceptors(FileInterceptor('imagen', { storage }))
  async create(
    @Body() dto: CreateAnimalDto,
    @UploadedFile() file?: Express.Multer.File,
  ): Promise<AnimalConRelaciones> {
    const urlImagen = file ? `uploads/animals/${file.filename}` : undefined;

    const edadEnMeses =
      dto.unidad_edad === 'años' ? Number(dto.edad) * 12 : Number(dto.edad);

    const spDto: RegistrarAnimalSpDto = {
      nombre: dto.nombre,
      especie: dto.especie,
      raza: dto.raza,
      edad: edadEnMeses,
      peso: Number(dto.peso),
      sexo: dto.sexo,
      tamano: dto.tamano,
      enfermedad_no_tratable: dto.enfermedad_no_tratable,
      discapacidad: dto.discapacidad,
      es_agresivo: dto.es_agresivo,
      lugar: dto.lugar,
      descripcion: dto.descripcion,
      usuario_id: dto.usuario_id,
      refugio_id: dto.refugio_id,
      url_imagen: urlImagen,
      estado: 'adopcion',
      tipo_movimiento: 'entrada',
      motivo: 'rescate',
      fecha_movimiento: new Date().toISOString(),
    };

    return this.animalsSpService.registrarAnimalCompleto(spDto);
  }

  @Patch(':id')
  @Roles('admin', 'propietario')
  @UseInterceptors(FileInterceptor('imagen', { storage }))
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateAnimalDto,
    @CurrentUser() user: UserResponse,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file) {
      dto.imagen = `uploads/animals/${file.filename}`;
    }
    return this.animalsService.update(id, dto, user.refugio.id_refugio);
  }

  @Delete('imagen/:imagenId')
  @Roles('admin', 'propietario')
  async deleteImagen(
    @Param('imagenId') imagenId: string,
    @CurrentUser() user: UserResponse,
  ) {
    return this.animalsService.deleteImagen(imagenId, user.refugio.id_refugio);
  }

  @Delete(':id')
  @Roles('admin', 'propietario')
  async delete(@Param('id') id: string, @CurrentUser() user: UserResponse) {
    return this.animalsService.delete(id, user.refugio.id_refugio);
  }
}
