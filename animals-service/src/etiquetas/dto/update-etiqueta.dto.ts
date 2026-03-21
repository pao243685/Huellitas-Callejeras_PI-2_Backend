import { PartialType } from '@nestjs/mapped-types';
import { CreateEtiquetaDto } from './etiqueta.dto';

export class UpdateEtiquetaDto extends PartialType(CreateEtiquetaDto) {}
