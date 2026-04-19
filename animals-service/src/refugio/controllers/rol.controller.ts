import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { RolService } from '../services/rol.service';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RefugioOwnershipGuard } from '../../auth/guards/refugio-asociado.guard';

@Controller('roles')
export class RolController {
  constructor(private readonly rolService: RolService) {}

  @Get('refugio/:refugio_id')
  @Roles('admin', 'propietario', 'colaborador')
  @UseGuards(RefugioOwnershipGuard)
  async findByRefugio(@Param('refugio_id') refugioId: string) {
    return this.rolService.findByrefugio(refugioId);
  }
}
