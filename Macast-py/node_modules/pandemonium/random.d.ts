import {RNGFunction} from './types';

type RandomFunction = (min: number, max: number) => number;

declare const random: {
  (min: number, max: number): number;
  createRandom(rng: RNGFunction): RandomFunction;
};

export function createRandom(rng: RNGFunction): RandomFunction;

export default random;
