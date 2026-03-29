import {RNGFunction} from './types';

type Alphabet = Array<string> | string;
type RandomStringFunction = (minLength: number, maxLength?: number) => string;

declare const randomString: {
  (minLength: number, maxLength?: number): string;
  createRandomString(
    rng: RNGFunction,
    alphabet?: Alphabet
  ): RandomStringFunction;
};

export function createRandomString(
  rng: RNGFunction,
  alphabet?: Alphabet
): RandomStringFunction;

export default randomString;
