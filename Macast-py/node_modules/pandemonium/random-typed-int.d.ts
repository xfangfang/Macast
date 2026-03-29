import {RNGFunction} from './types';

export function createRandomUint32(rng: RNGFunction): () => number;
export function randomUint32(): number;
