import { localDb } from '../data/db/local-db';
import { Review } from '../types/domain';

export class ReviewRepository {
  list(): Review[] {
    return localDb.getReviews();
  }

  listByToUser(toUserId: string): Review[] {
    return localDb.getReviews().filter((review: Review) => review.toUserId === toUserId);
  }

  listByOrder(orderId: string): Review[] {
    return localDb.getReviews().filter((review: Review) => review.orderId === orderId);
  }

  save(review: Review): Review {
    const reviews: Review[] = localDb.getReviews();
    const index: number = reviews.findIndex((r: Review) => r.id === review.id);
    if (index >= 0) {
      reviews[index] = review;
    } else {
      reviews.push(review);
    }
    localDb.setReviews(reviews);
    return review;
  }
}

export const reviewRepository: ReviewRepository = new ReviewRepository();
