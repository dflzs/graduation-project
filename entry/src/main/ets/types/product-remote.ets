export interface RemoteProductItem {
  id: number;
  seller_id: number;
  title: string;
  description: string;
  price: string | number;
  category: string;
  location_tag: string;
  school_id?: string;
  school_name?: string;
  campus_id?: string;
  campus_name?: string;
  location_group_id?: string;
  location_group_name?: string;
  trade_location_id?: string;
  trade_location_name?: string;
  location_safety_tips?: string;
  cover_image: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export class RemoteCreateProductPayload {
  title: string = '';
  description: string = '';
  price: number = 0;
  category: string = '';
  location_tag: string = '';
  school_id?: string;
  campus_id?: string;
  location_group_id?: string;
  trade_location_id?: string;
  cover_image: string = '';

  constructor(
    title: string,
    description: string,
    price: number,
    category: string,
    locationTag: string,
    coverImage: string = '',
    schoolId?: string,
    campusId?: string,
    locationGroupId?: string,
    tradeLocationId?: string
  ) {
    this.title = title;
    this.description = description;
    this.price = price;
    this.category = category;
    this.location_tag = locationTag;
    this.cover_image = coverImage;
    this.school_id = schoolId;
    this.campus_id = campusId;
    this.location_group_id = locationGroupId;
    this.trade_location_id = tradeLocationId;
  }
}

export interface RemoteProductListResponse {
  code: number;
  message: string;
  data?: RemoteProductItem[];
}

export interface RemoteProductDetailResponse {
  code: number;
  message: string;
  data?: RemoteProductItem;
}

export interface RemoteCreateProductResponse {
  code: number;
  message: string;
  data?: RemoteProductItem;
}

export interface RemoteProductQuery {
  keyword?: string;
  category?: string;
  status?: string;
}
