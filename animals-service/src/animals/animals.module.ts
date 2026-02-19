import { Module } from '@nestjs/common';
import { AnimalsController } from './controllers/animals.controller';
import { AnimalsService } from './services/animals.service';
import { AnimalsValidationService } from './services/animals.validation.service';
import { AnimalEventPublisher } from '../events/publishers/animal-event-publisher';
import { PrismaService } from '../shared/prisma/prisma.service';
import { RabbitmqService } from '../shared/messaging/rabbitmq.service';

@Module({
  controllers: [AnimalsController],
  providers: [
    AnimalsService,
    AnimalsValidationService,
    AnimalEventPublisher,
    PrismaService,
    RabbitmqService,
  ],
  exports: [AnimalsService],
})
export class AnimalsModule {}
