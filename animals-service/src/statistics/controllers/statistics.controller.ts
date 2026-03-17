import { Controller, Get, Param, Query } from '@nestjs/common';
import { StatisticsService } from '../services/statistics.service';
import { Roles } from '../../auth/decorators/roles.decorator';
import { HistorialDto } from '../dto/historial.dto';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('indicadores/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  async getIndicadores(@Param('refugio_id') refugioId: string) {
    return this.statisticsService.getIndicadores(refugioId);
  }

  @Get('historial/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  async getHistorial(
    @Param('refugio_id') refugioId: string,
    @Query() query: HistorialDto,
  ) {
    return this.statisticsService.getHistorial(
      refugioId,
      query.fecha_ini,
      query.fecha_fin,
      query.modo,
    );
  }
}
