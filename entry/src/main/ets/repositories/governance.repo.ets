import { localDb } from '../data/db/local-db';
import { normalizeGovernanceAction } from '../data/db/persisted-state';
import { GovernanceAction } from '../types/domain';

export class GovernanceRepository {
  private isEffectivelyActive(record: GovernanceAction): boolean {
    const now = Date.now();
    return record.active && record.startAt <= now && (record.endAt === undefined || record.endAt > now);
  }

  list(): GovernanceAction[] {
    return localDb.getGovernanceActions()
      .sort((left: GovernanceAction, right: GovernanceAction) => right.updatedAt - left.updatedAt);
  }

  listByUser(userId: string): GovernanceAction[] {
    return this.list().filter((item: GovernanceAction) => item.userId === userId);
  }

  listActiveByUser(userId: string): GovernanceAction[] {
    return this.listByUser(userId).filter((item: GovernanceAction) => this.isEffectivelyActive(item));
  }

  getById(actionId: string): GovernanceAction | null {
    const record = localDb.getGovernanceActions().find((item: GovernanceAction) => item.id === actionId);
    return record ?? null;
  }

  save(record: GovernanceAction): GovernanceAction {
    const normalized = normalizeGovernanceAction(record);
    const items = localDb.getGovernanceActions();
    const index = items.findIndex((item: GovernanceAction) => item.id === normalized.id);
    if (index >= 0) {
      items[index] = normalized;
    } else {
      items.push(normalized);
    }
    localDb.setGovernanceActions(items);
    return normalized;
  }

  replaceAll(records: GovernanceAction[]): GovernanceAction[] {
    localDb.setGovernanceActions(records.map((record: GovernanceAction) => normalizeGovernanceAction(record)));
    return this.list();
  }

  replaceByUser(userId: string, records: GovernanceAction[]): GovernanceAction[] {
    const normalized = records.map((record: GovernanceAction) => normalizeGovernanceAction(record));
    const retained = localDb.getGovernanceActions().filter((item: GovernanceAction) => item.userId !== userId);
    localDb.setGovernanceActions([...retained, ...normalized]);
    return this.listByUser(userId);
  }
}

export const governanceRepository: GovernanceRepository = new GovernanceRepository();
