"use strict";

const assert = require("assert");

class QueryResult {
  /**
   * Internal constructor. Use `Connection.query` or `Connection.execute`
   * to get a `QueryResult` object.
   * @param {Connection} connection the connection object.
   * @param {LbugNative.NodeQueryResult} queryResult the native query result object.
   */
  constructor(connection, queryResult) {
    assert(
      typeof connection === "object" &&
        connection.constructor.name === "Connection"
    );
    assert(
      typeof queryResult === "object" &&
        queryResult.constructor.name === "NodeQueryResult"
    );
    this._connection = connection;
    this._queryResult = queryResult;
    this._isClosed = false;
  }

  /**
   * Reset the iterator of the query result to the beginning.
   * This function is useful if the query result is iterated multiple times.
   */
  resetIterator() {
    this._checkClosed();
    this._queryResult.resetIterator();
  }

  /**
   * Check if the query result has more rows.
   * @returns {Boolean} true if the query result has more rows.
   */
  hasNext() {
    this._checkClosed();
    return this._queryResult.hasNext();
  }

  /**
   * Get the number of rows of the query result.
   * @returns {Number} the number of rows of the query result.
   */
  getNumTuples() {
    this._checkClosed();
    return this._queryResult.getNumTuples();
  }

  /**
   * Get the next row of the query result.
   * @returns {Promise<Object>} a promise that resolves to the next row of the query result. The promise is rejected if there is an error.
   */
  getNext() {
    this._checkClosed();
    return new Promise((resolve, reject) => {
      this._queryResult.getNextAsync((err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      });
    });
  }

  /**
   * Get the next row of the query result synchronously.
   * @returns {Object} the next row of the query result.
   */
  getNextSync() {
    this._checkClosed();
    return this._queryResult.getNextSync();
  }

  /**
   * Iterate through the query result with callback functions.
   * @param {Function} resultCallback the callback function that is called for each row of the query result.
   * @param {Function} doneCallback the callback function that is called when the iteration is done.
   * @param {Function} errorCallback the callback function that is called when there is an error.
   */
  each(resultCallback, doneCallback, errorCallback) {
    this._checkClosed();
    if (!this.hasNext()) {
      return doneCallback();
    }
    this.getNext()
      .then((row) => {
        resultCallback(row);
        this.each(resultCallback, doneCallback, errorCallback);
      })
      .catch((err) => {
        errorCallback(err);
      });
  }

  /**
   * Get all rows of the query result.
   * @returns {Promise<Array<Object>>} a promise that resolves to all rows of the query result. The promise is rejected if there is an error.
   */
  async getAll() {
    this._checkClosed();
    this._queryResult.resetIterator();
    const result = [];
    while (this.hasNext()) {
      result.push(await this.getNext());
    }
    return result;
  }

  /**
   * Get all rows of the query result synchronously. Note that this function can block the main thread if the number of rows is large, so use it with caution.
   * @returns {Array<Object>} all rows of the query result.
   */
  getAllSync() {
    this._checkClosed();
    this._queryResult.resetIterator();
    const result = [];
    while (this.hasNext()) {
      result.push(this.getNextSync());
    }
    return result;
  }

  /**
   * Get all rows of the query result with callback functions.
   * @param {Function} resultCallback the callback function that is called with all rows of the query result.
   * @param {Function} errorCallback the callback function that is called when there is an error.
   */
  all(resultCallback, errorCallback) {
    this._checkClosed();
    this.getAll()
      .then((result) => {
        resultCallback(result);
      })
      .catch((err) => {
        errorCallback(err);
      });
  }

  /**
   * Get the data types of the columns of the query result.
   * @returns {Promise<Array<String>>} a promise that resolves to the data types of the columns of the query result. The promise is rejected if there is an error.
   */
  getColumnDataTypes() {
    this._checkClosed();
    return new Promise((resolve, reject) => {
      this._queryResult.getColumnDataTypesAsync((err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      });
    });
  }

  /**
   * Get the data types of the columns of the query result synchronously.
   * @returns {Array<String>} the data types of the columns of the query result.
   */
  getColumnDataTypesSync() {
    this._checkClosed();
    return this._queryResult.getColumnDataTypesSync();
  }

  /**
   * Get the names of the columns of the query result.
   * @returns {Promise<Array<String>>} a promise that resolves to the names of the columns of the query result. The promise is rejected if there is an error.
   */
  getColumnNames() {
    this._checkClosed();
    return new Promise((resolve, reject) => {
      this._queryResult.getColumnNamesAsync((err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      });
    });
  }

  /**
   * Get the names of the columns of the query result synchronously.
   * @returns {Array<String>} the names of the columns of the query result.
   */
  getColumnNamesSync() {
    this._checkClosed();
    return this._queryResult.getColumnNamesSync();
  }

  /**
   * Get the query summary (compiling and execution time) of the query result.
   * @returns {Promise<Object>} a promise that resolves to the query summary of the query result. The promise is rejected if there is an error.
   */
  getQuerySummary() {
    this._checkClosed();
    return new Promise((resolve, reject) => {
      this._queryResult.getQuerySummaryAsync((err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      });
    });
  }

  /**
   * Get the query summary (compiling and execution time) of the query result synchronously.
   * @returns {Object} the query summary of the query result.
   */
  getQuerySummarySync() {
    this._checkClosed();
    return this._queryResult.getQuerySummarySync();
  }

  /**
   * Close the query result.
   */
  close() {
    if (this._isClosed) {
      return;
    }
    this._queryResult.close();
    delete this._queryResult;
    this._connection = null;
    this._isClosed = true;
  }

  /**
   * Internal function to check if the query result is closed.
   * @throws {Error} if the query result is closed.
   */
  _checkClosed() {
    if (this._isClosed) {
      throw new Error("Query result is closed.");
    }
  }
}

module.exports = QueryResult;
