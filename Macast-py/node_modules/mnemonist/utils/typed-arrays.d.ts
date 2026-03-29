export type PointerArray = Uint8Array | Uint16Array | Uint32Array | Float64Array;
export type SignedPointerArray = Int8Array | Int16Array | Int32Array | Float64Array;
export type PointerArrayConstructor = Uint8ArrayConstructor | Uint16ArrayConstructor | Uint32ArrayConstructor | Float64ArrayConstructor;
export type SignedPointerArrayConstructor = Int8ArrayConstructor | Int16ArrayConstructor | Int32ArrayConstructor | Float64ArrayConstructor;

export function getPointerArray(size: number): PointerArrayConstructor;
export function getSignedPointerArray(size: number): SignedPointerArrayConstructor;
export function getNumberType(value: number): PointerArrayConstructor | SignedPointerArrayConstructor;
export function isTypedArray(value: unknown): boolean;
export function indices(length: number): PointerArray;
