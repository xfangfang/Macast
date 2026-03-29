import {RNGFunction} from './types';

type ShuffleInPlaceFunction<T> = (array: Array<T>) => void;

declare const shuffleInPlace: {
  <T>(array: Array<T>): void;
  createShuffleInPlace<T>(rng: RNGFunction): ShuffleInPlaceFunction<T>;
};

export function createShuffleInPlace<T>(
  rng: RNGFunction
): ShuffleInPlaceFunction<T>;

export default shuffleInPlace;
