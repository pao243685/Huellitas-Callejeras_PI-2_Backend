import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express/multer/multer.module';
import { AnimalsController } from './controllers/animals.controller';
import { AnimalsService } from './services/animals.service';
import { AnimalsValidationService } from './services/animals.validation.service';
import { AnimalsSpService } from './services/animals.sp.service';

import { PrismaService } from '../shared/prisma/prisma.service';

@Module({
  imports: [MulterModule.register({ dest: './uploads/animals' })],
  controllers: [AnimalsController],
  providers: [
    AnimalsService,
    AnimalsValidationService,
    AnimalsSpService,
    PrismaService,
  ],
  exports: [AnimalsService, AnimalsSpService],
})
export class AnimalsModule {}
