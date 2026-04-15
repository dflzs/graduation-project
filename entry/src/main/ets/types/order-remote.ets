export interface RemoteOrderItem {
  id: number | string;
  order_no?: string;
  product_id: number | string;
  buyer_id: number | string;
  seller_id: number | string;
  amount: number | string;
  address: string;
  location_tag: string;
  pay_type: string;
  status: string;
  buyer_arrived: number | boolean;
  seller_arrived: number | boolean;
  created_at: string | number;
  updated_at: string | number;
  school_id?: string;
  school_name?: string;
  campus_id?: string;
  campus_name?: string;
  location_group_id?: string;
  location_group_name?: string;
  trade_location_id?: string;
  trade_location_name?: string;
  location_safety_tips?: string;
}

export class RemoteCreateOrderPayload {
  product_id: string = '';
  address: string = '';
  location_tag: string = '';

  constructor(productId: string, address: string, locationTag: string) {
    this.product_id = productId;
    this.address = address;
    this.location_tag = locationTag;
  }
}

export interface RemoteOrderListResponse {
  code: number;
  message: string;
  data?: RemoteOrderItem[];
}

export interface RemoteOrderDetailResponse {
  code: number;
  message: string;
  data?: RemoteOrderItem;
}
