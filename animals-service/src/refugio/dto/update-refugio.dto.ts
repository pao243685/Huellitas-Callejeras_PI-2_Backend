import { PartialType } from '@nestjs/mapped-types';
import { CreateRefugioDto } from './create-refugio.dto';

export class UpdateRefugioDto extends PartialType(CreateRefugioDto) {}
