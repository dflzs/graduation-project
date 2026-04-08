import { describe, it, expect } from '@ohos/hypium';
import { appContext } from '../../../main/ets/app/app-context';
import { orderRepository } from '../../../main/ets/repositories/order.repo';

export default function abilityTest() {
  describe('CampusMarketScenarioTest', () => {
    it('user_flow_should_create_and_pay_order', 0, () => {
      const login = appContext.auth.loginByPhone('18866668888', '123456');
      expect(login.ok).assertTrue();
      const user = login.data!.currentUser;

      const products = appContext.listPublicProducts('', '全部');
      expect(products.length > 0).assertTrue();

      const create = appContext.order.createOrder(user.id, products[0].id, '图书馆大厅-测试地址');
      expect(create.ok).assertTrue();

      const pay = appContext.order.simulatePay(create.data!.id, user.id);
      expect(pay.ok).assertTrue();

      const stored = orderRepository.getById(create.data!.id);
      expect(stored !== null).assertTrue();
      expect(stored!.status).assertEqual('PAID_SIMULATED');
    });

    it('admin_flow_should_publish_announcement', 0, () => {
      const login = appContext.auth.loginByAdminCode('18899990000', 'ADMIN2026');
      expect(login.ok).assertTrue();
      const admin = login.data!.currentUser;

      const publish = appContext.announcement.publish('测试公告', '这是集成测试公告', admin.id);
      expect(publish.ok).assertTrue();

      const list = appContext.announcement.list();
      expect(list.length > 0).assertTrue();
    });
  });
}
