import {RNGFunction} from './types';

export class FisherYatesPermutation {
  length: number;

  constructor(length: number, rng?: RNGFunction);
  permute(): number;
  reset(): void;
  shrink(newLength: number): void;
}
