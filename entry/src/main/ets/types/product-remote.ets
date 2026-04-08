export interface RemoteProductItem {
  id: number;
  seller_id: number;
  title: string;
  description: string;
  price: string | number;
  category: string;
  location_tag: string;
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
  cover_image: string = '';

  constructor(
    title: string,
    description: string,
    price: number,
    category: string,
    locationTag: string,
    coverImage: string = ''
  ) {
    this.title = title;
    this.description = description;
    this.price = price;
    this.category = category;
    this.location_tag = locationTag;
    this.cover_image = coverImage;
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
