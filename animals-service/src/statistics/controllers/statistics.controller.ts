import { Controller, Get, Param } from '@nestjs/common';
import { StatisticsService } from '../services/statistics.service';
import { Roles } from '../../auth/decorators/roles.decorator';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('indicadores/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  async getIndicadores(@Param('refugio_id') refugioId: string) {
    return this.statisticsService.getIndicadores(refugioId);
  }
}
