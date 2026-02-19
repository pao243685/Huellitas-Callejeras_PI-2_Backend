import { Module } from '@nestjs/common';
import { MovementsController } from './controllers/movements.controller';
import { MovementsService } from './services/movements.service';
import { MovementsValidationService } from './services/movements.validation.service';
import { SharedModule } from '../shared/shared.module';

@Module({
  imports: [SharedModule],
  controllers: [MovementsController],
  providers: [MovementsService, MovementsValidationService],
})
export class MovementsModule {}
