import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { RabbitmqService } from './messaging/rabbitmq.service';

@Global()
@Module({
  providers: [PrismaService, RabbitmqService],
  exports: [PrismaService, RabbitmqService],
})
export class SharedModule {}
