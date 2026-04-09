import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express/multer/multer.module';

// Controllers
import { AnimalsController } from './controllers/animals.controller';
import { AnimalsSpController } from './controllers/animals.sp.controller'; 

// Services
import { AnimalsService } from './services/animals.service';
import { AnimalsValidationService } from './services/animals.validation.service';
import { AnimalsSpService } from './services/animals.sp.service';         

// Shared
import { PrismaService } from '../shared/prisma/prisma.service';

@Module({
  imports: [MulterModule.register({ dest: './uploads/animals' })],
  controllers: [
    AnimalsController,
    AnimalsSpController,  
  ],
  providers: [
    AnimalsService,
    AnimalsValidationService,
    AnimalsSpService,     
    PrismaService,
  ],
  exports: [AnimalsService, AnimalsSpService],
})
export class AnimalsModule {}