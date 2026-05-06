import { ForbiddenException } from '@nestjs/common';
import { MatchingEngineController } from './matching-engine.controller';
import { MatchingEngineService } from './matching-engine.service';

describe('MatchingEngineController', () => {
  let controller: MatchingEngineController;
  let service: {
    getCurrentMomentsForUser: jest.Mock;
    getMomentHistoryForUser: jest.Mock;
    runDueWork: jest.Mock;
    optInToGroupMoment: jest.Mock;
  };

  beforeEach(() => {
    service = {
      getCurrentMomentsForUser: jest.fn(),
      getMomentHistoryForUser: jest.fn(),
      runDueWork: jest.fn(),
      optInToGroupMoment: jest.fn(),
    };

    controller = new MatchingEngineController(
      service as unknown as MatchingEngineService,
    );
  });

  it('returns current moments for the authenticated user', async () => {
    service.getCurrentMomentsForUser.mockResolvedValue([{ id: 'moment-1' }]);

    const result = await controller.getCurrentMoments({
      user: { id: 'user-1' },
    } as any);

    expect(result).toEqual([{ id: 'moment-1' }]);
    expect(service.getCurrentMomentsForUser).toHaveBeenCalledWith('user-1');
  });

  it('returns paginated moment history for the authenticated user', async () => {
    service.getMomentHistoryForUser.mockResolvedValue({
      items: [],
      nextCursor: null,
    });

    const result = await controller.getMomentHistory(
      { user: { id: 'user-1' } } as any,
      { limit: 10, cursor: 'cursor-1' },
    );

    expect(result).toEqual({ items: [], nextCursor: null });
    expect(service.getMomentHistoryForUser).toHaveBeenCalledWith(
      'user-1',
      10,
      'cursor-1',
    );
  });

  it('runs due matching work', async () => {
    service.runDueWork.mockResolvedValue({ created: { friend: 0, group: 0 } });

    const result = await controller.runDueWork(
      { dailyTimeUtc: '16:00' },
      'true',
    );

    expect(result).toEqual({ created: { friend: 0, group: 0 } });
    expect(service.runDueWork).toHaveBeenCalledWith(
      expect.any(Date),
      '16:00',
      true,
    );
  });

  it('records group moment opt-in for the authenticated participant', async () => {
    service.optInToGroupMoment.mockResolvedValue({ id: 'moment-1' });

    const result = await controller.optInToGroupMoment(
      'moment-1',
      { user: { id: 'user-1' } } as any,
    );

    expect(result).toEqual({ id: 'moment-1' });
    expect(service.optInToGroupMoment).toHaveBeenCalledWith(
      'moment-1',
      'user-1',
    );
  });

  it('rejects missing authenticated user context', async () => {
    await expect(controller.getCurrentMoments({} as any)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
