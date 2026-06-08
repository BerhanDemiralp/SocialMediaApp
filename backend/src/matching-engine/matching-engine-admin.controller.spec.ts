import { MatchingEngineAdminController } from './matching-engine-admin.controller';
import { MatchingEngineService } from './matching-engine.service';

describe('MatchingEngineAdminController', () => {
  let controller: MatchingEngineAdminController;
  let service: {
    runDueWork: jest.Mock;
    getSettings: jest.Mock;
    updateSettings: jest.Mock;
  };

  beforeEach(() => {
    service = {
      runDueWork: jest.fn(),
      getSettings: jest.fn(),
      updateSettings: jest.fn(),
    };

    controller = new MatchingEngineAdminController(
      service as unknown as MatchingEngineService,
    );
  });

  it('returns matching settings', async () => {
    service.getSettings.mockResolvedValue({
      dailyTimeLocal: '19:00',
      timezone: 'Europe/Istanbul',
    });

    const result = await controller.getSettings();

    expect(result).toEqual({
      dailyTimeLocal: '19:00',
      timezone: 'Europe/Istanbul',
    });
    expect(service.getSettings).toHaveBeenCalled();
  });

  it('updates matching settings', async () => {
    service.updateSettings.mockResolvedValue({
      dailyTimeLocal: '20:30',
      timezone: 'Europe/Istanbul',
    });

    const result = await controller.updateSettings({
      dailyTimeLocal: '20:30',
      timezone: 'Europe/Istanbul',
    });

    expect(result).toEqual({
      dailyTimeLocal: '20:30',
      timezone: 'Europe/Istanbul',
    });
    expect(service.updateSettings).toHaveBeenCalledWith({
      dailyTimeLocal: '20:30',
      timezone: 'Europe/Istanbul',
    });
  });

  it('runs due matching work for admin debugging', async () => {
    service.runDueWork.mockResolvedValue({ created: { friend: 0, group: 0 } });

    const result = await controller.runDueWork(
      { dailyTimeLocal: '19:00' },
      'true',
    );

    expect(result).toEqual({ created: { friend: 0, group: 0 } });
    expect(service.runDueWork).toHaveBeenCalledWith(
      expect.any(Date),
      '19:00',
      true,
    );
  });
});
