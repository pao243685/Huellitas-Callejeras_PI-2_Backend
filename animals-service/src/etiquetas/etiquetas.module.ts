import { Module } from '@nestjs/common';
import { EtiquetasController } from './controllers/etiquetas.controller';
import { EtiquetasService } from './services/etiquetas.service';
import { SharedModule } from '../shared/shared.module';

@Module({
  imports: [SharedModule],
  controllers: [EtiquetasController],
  providers: [EtiquetasService],
  exports: [EtiquetasService],
})
export class EtiquetasModule {}
