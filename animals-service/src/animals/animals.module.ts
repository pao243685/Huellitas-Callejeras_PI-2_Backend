import { Module } from '@nestjs/common';
import { AnimalsController } from './controllers/animals.controller';
import { AnimalsService } from './services/animals.service';
import { AnimalsValidationService } from './services/animals.validation.service';
import { PrismaService } from '../shared/prisma/prisma.service';
import { MulterModule } from '@nestjs/platform-express/multer/multer.module';

@Module({
  imports: [MulterModule.register({ dest: './uploads/animals' })],
  controllers: [AnimalsController],
  providers: [AnimalsService, AnimalsValidationService, PrismaService],
  exports: [AnimalsService],
})
export class AnimalsModule {}
