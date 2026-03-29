/**
 * Mnemonist LRUMapWithDelete
 * ===========================
 *
 * An extension of LRUMap with delete functionality.
 */

var LRUMap = require('./lru-map.js'),
    forEach = require('obliterator/foreach'),
    typed = require('./utils/typed-arrays.js'),
    iterables = require('./utils/iterables.js');

// The only complication with deleting items is that the LRU's
// performance depends on having a fixed-size list of pointers; the
// doubly-linked-list is happy to expand and contract.
//
// On delete, we record the position of the former item's pointer in a
// list of "holes" in the pointer array. On insert, if there is a hole
// the new pointer slots in to fill the hole; otherwise, it is
// appended as usual. (Note: we are only talking here about the
// internal pointer list. setting or getting an item promotes it
// to the top of the LRU ranking no matter what came before)

function LRUMapWithDelete(Keys, Values, capacity) {
  if (arguments.length < 2) {
    LRUMap.call(this, Keys);
  }
  else {
    LRUMap.call(this, Keys, Values, capacity);
  }
  var PointerArray = typed.getPointerArray(this.capacity);
  this.deleted = new PointerArray(this.capacity);
  this.deletedSize = 0;
}

for (var k in LRUMap.prototype)
  LRUMapWithDelete.prototype[k] = LRUMap.prototype[k];
if (typeof Symbol !== 'undefined')
  LRUMapWithDelete.prototype[Symbol.iterator] = LRUMap.prototype[Symbol.iterator];

/**
 * Method used to clear the structure.
 *
 * @return {undefined}
 */
LRUMapWithDelete.prototype.clear = function() {
  LRUMap.prototype.clear.call(this);
  this.deletedSize = 0;
};

/**
 * Method used to set the value for the given key in the cache.
 *
 * @param  {any} key   - Key.
 * @param  {any} value - Value.
 * @return {undefined}
 */
LRUMapWithDelete.prototype.set = function(key, value) {

  var pointer = this.items.get(key);

  // The key already exists, we just need to update the value and splay on top
  if (typeof pointer !== 'undefined') {
    this.splayOnTop(pointer);
    this.V[pointer] = value;

    return;
  }

  // The cache is not yet full
  if (this.size < this.capacity) {
    if (this.deletedSize > 0) {
      // If there is a "hole" in the pointer list, reuse it
      pointer = this.deleted[--this.deletedSize];
    }
    else {
      // otherwise append to the pointer list
      pointer = this.size;
    }
    this.size++;
  }

  // Cache is full, we need to drop the last value
  else {
    pointer = this.tail;
    this.tail = this.backward[pointer];
    this.items.delete(this.K[pointer]);
  }

  // Storing key & value
  this.items.set(key, pointer);
  this.K[pointer] = key;
  this.V[pointer] = value;

  // Moving the item at the front of the list
  this.forward[pointer] = this.head;
  this.backward[this.head] = pointer;
  this.head = pointer;
};

/**
 * Method used to set the value for the given key in the cache
 *
 * @param  {any} key   - Key.
 * @param  {any} value - Value.
 * @return {{evicted: boolean, key: any, value: any}} An object containing the
 * key and value of an item that was overwritten or evicted in the set
 * operation, as well as a boolean indicating whether it was evicted due to
 * limited capacity. Return value is null if nothing was evicted or overwritten
 * during the set operation.
 */
LRUMapWithDelete.prototype.setpop = function(key, value) {
  var oldValue = null;
  var oldKey = null;

  var pointer = this.items.get(key);

  // The key already exists, we just need to update the value and splay on top
  if (typeof pointer !== 'undefined') {
    this.splayOnTop(pointer);
    oldValue = this.V[pointer];
    this.V[pointer] = value;
    return {evicted: false, key: key, value: oldValue};
  }

  // The cache is not yet full
  if (this.size < this.capacity) {
    if (this.deletedSize > 0) {
      // If there is a "hole" in the pointer list, reuse it
      pointer = this.deleted[--this.deletedSize];
    }
    else {
      // otherwise append to the pointer list
      pointer = this.size;
    }
    this.size++;
  }

  // Cache is full, we need to drop the last value
  else {
    pointer = this.tail;
    this.tail = this.backward[pointer];
    oldValue = this.V[pointer];
    oldKey = this.K[pointer];
    this.items.delete(oldKey);
  }

  // Storing key & value
  this.items.set(key, pointer);
  this.K[pointer] = key;
  this.V[pointer] = value;

  // Moving the item at the front of the list
  this.forward[pointer] = this.head;
  this.backward[this.head] = pointer;
  this.head = pointer;

  // Return object if eviction took place, otherwise return null
  if (oldKey) {
    return {evicted: true, key: oldKey, value: oldValue};
  }
  else {
    return null;
  }
};

/**
 * Method used to delete the entry for the given key in the cache.
 *
 * @param  {any} key   - Key.
 * @return {boolean}   - true if the item was present
 */
LRUMapWithDelete.prototype.delete = function(key) {

  var pointer = this.items.get(key);

  if (typeof pointer === 'undefined') {
    return false;
  }

  this.items.delete(key);

  if (this.size === 1) {
    this.size = 0;
    this.head = 0;
    this.tail = 0;
    this.deletedSize = 0;
    return true;
  }

  var previous = this.backward[pointer],
      next = this.forward[pointer];

  if (this.head === pointer) {
    this.head = next;
  }
  if (this.tail === pointer) {
    this.tail = previous;
  }

  this.forward[previous] = next;
  this.backward[next] = previous;

  this.size--;
  this.deleted[this.deletedSize++] = pointer;

  return true;
};

/**
 * Method used to remove and return the value for the given key in the cache.
 *
 * @param  {any} key                 - Key.
 * @param  {any} [missing=undefined] - Value to return if item is absent
 * @return {any} The value, if present; the missing indicator if absent
 */
LRUMapWithDelete.prototype.remove = function(key, missing = undefined) {

  var pointer = this.items.get(key);

  if (typeof pointer === 'undefined') {
    return missing;
  }

  var dead = this.V[pointer];
  this.items.delete(key);

  if (this.size === 1) {
    this.size = 0;
    this.head = 0;
    this.tail = 0;
    this.deletedSize = 0;
    return dead;
  }

  var previous = this.backward[pointer],
      next = this.forward[pointer];

  if (this.head === pointer) {
    this.head = next;
  }
  if (this.tail === pointer) {
    this.tail = previous;
  }

  this.forward[previous] = next;
  this.backward[next] = previous;

  this.size--;
  this.deleted[this.deletedSize++] = pointer;

  return dead;
};

/**
 * Static @.from function taking an arbitrary iterable & converting it into
 * a structure.
 *
 * @param  {Iterable} iterable - Target iterable.
 * @param  {function} Keys     - Array class for storing keys.
 * @param  {function} Values   - Array class for storing values.
 * @param  {number}   capacity - Cache's capacity.
 * @return {LRUMapWithDelete}
 */
LRUMapWithDelete.from = function(iterable, Keys, Values, capacity) {
  if (arguments.length < 2) {
    capacity = iterables.guessLength(iterable);

    if (typeof capacity !== 'number')
      throw new Error('mnemonist/lru-map.from: could not guess iterable length. Please provide desired capacity as last argument.');
  }
  else if (arguments.length === 2) {
    capacity = Keys;
    Keys = null;
    Values = null;
  }

  var cache = new LRUMapWithDelete(Keys, Values, capacity);

  forEach(iterable, function(value, key) {
    cache.set(key, value);
  });

  return cache;
};

module.exports = LRUMapWithDelete;
