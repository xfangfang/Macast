export function indices(length: number): Array<number>;
export function triuLinearLength(n: number): number;
export function linearIndexToTriuCoords(
  n: number,
  k: number
): [i: number, j: number];
export function triuCoordsToLinearIndex(
  n: number,
  i: number,
  j: number
): number;
export function linearIndexToTriuCoordsFast(k: number);
export function createPairKeyFunction(
  n: number
): (i: number, j: number) => string | number;
