"use strict";

const LbugNative = require("./lbug_native.js");
const QueryResult = require("./query_result.js");
const PreparedStatement = require("./prepared_statement.js");

class Connection {
  /**
   * Initialize a new Connection object. Note that the initialization is done
   * lazily, so the connection is not initialized until the first query is
   * executed. To initialize the connection immediately, call the `init()`
   * function on the returned object.
   *
   * @param {lbug.Database} database the database object to connect to.
   * @param {Number} numThreads the maximum number of threads to use for query execution.
   */
  constructor(database, numThreads = null) {
    if (
      typeof database !== "object" ||
      database.constructor.name !== "Database"
    ) {
      throw new Error("database must be a valid Database object.");
    }
    this._database = database;
    this._connection = null;
    this._isInitialized = false;
    this._initPromise = null;
    this._isClosed = false;
    numThreads = parseInt(numThreads);
    if (numThreads && numThreads > 0) {
      this._numThreads = numThreads;
    }
  }

  /**
   * Initialize the connection. Calling this function is optional, as the
   * connection is initialized automatically when the first query is executed.
   */
  async init() {
    if (this._isClosed) {
      throw new Error("Connection is closed.");
    }
    if (!this._isInitialized) {
      if (!this._initPromise) {
        if (!this._connection) {
          const database = await this._database._getDatabase();
          this._connection = new LbugNative.NodeConnection(database);
        }
        this._initPromise = new Promise((resolve, reject) => {
          this._connection.initAsync((err) => {
            if (err) {
              reject(err);
            } else {
              this._isInitialized = true;
              if (this._numThreads) {
                this._connection.setMaxNumThreadForExec(this._numThreads);
              }
              if (this._queryTimeout) {
                this._connection.setQueryTimeout(this._queryTimeout);
              }
              resolve();
            }
          });
        });
      }
      await this._initPromise;
      this._initPromise = null;
    }
  }

  /**
   * Initialize the connection synchronously. Calling this function is optional, as the
   * connection is initialized automatically when the first query is executed. This function
   * may block the main thread, so use it with caution.
   */
  initSync() {
    if (this._isClosed) {
      throw new Error("Connection is closed.");
    }
    if (this._isInitialized) {
      return;
    }
    if (this._initPromise) {
      throw new Error("There is an ongoing asynchronous initialization. Please wait for it to finish.");
    }
    if (!this._connection) {
      const database = this._database._getDatabaseSync();
      this._connection = new LbugNative.NodeConnection(database);
    }
    this._connection.initSync();
    this._isInitialized = true;
  }

  /**
   * Internal function to get the underlying native connection object.
   * @returns {LbugNative.NodeConnection} the underlying native connection.
   * @throws {Error} if the connection is closed.
   */
  async _getConnection() {
    if (this._isClosed) {
      throw new Error("Connection is closed.");
    }
    await this.init();
    return this._connection;
  }

  /**
   * Internal function to get the underlying native connection object synchronously.
   * @returns {LbugNative.NodeConnection} the underlying native connection.
   * @throws {Error} if the connection is closed.
   */
  _getConnectionSync() {
    if (this._isClosed) {
      throw new Error("Connection is closed.");
    }
    this.initSync();
    return this._connection;
  }

  /**
   * Execute a prepared statement with the given parameters.
   * @param {lbug.PreparedStatement} preparedStatement the prepared statement to execute.
   * @param {Object} params a plain object mapping parameter names to values.
   * @param {Function} [progressCallback] - Optional callback function that is invoked with the progress of the query execution. The callback receives three arguments: pipelineProgress, numPipelinesFinished, and numPipelines.
   * @returns {Promise<lbug.QueryResult>} a promise that resolves to the query result. The promise is rejected if there is an error.
   */
  execute(preparedStatement, params = {}, progressCallback) {
    return new Promise((resolve, reject) => {
      if (
        !typeof preparedStatement === "object" ||
        preparedStatement.constructor.name !== "PreparedStatement"
      ) {
        return reject(
          new Error(
            "preparedStatement must be a valid PreparedStatement object."
          )
        );
      }
      if (!preparedStatement.isSuccess()) {
        return reject(new Error(preparedStatement.getErrorMessage()));
      }
      if (params.constructor !== Object) {
        return reject(new Error("params must be a plain object."));
      }
      const paramArray = [];
      for (const key in params) {
        const value = params[key];
        paramArray.push([key, value]);
      }
      if (progressCallback && typeof progressCallback !== "function") {
        return reject(new Error("progressCallback must be a function."));
      }
      this._getConnection()
        .then((connection) => {
          const nodeQueryResult = new LbugNative.NodeQueryResult();
          try {
            connection.executeAsync(
              preparedStatement._preparedStatement,
              nodeQueryResult,
              paramArray,
              (err) => {
                if (err) {
                  return reject(err);
                }
                this._unwrapMultipleQueryResults(nodeQueryResult)
                  .then((queryResults) => {
                    return resolve(queryResults);
                  })
                  .catch((err) => {
                    return reject(err);
                  });
              },
              progressCallback
            );
          } catch (e) {
            return reject(e);
          }
        })
        .catch((err) => {
          return reject(err);
        });
    });
  }

  /**
   * Execute a prepared statement with the given parameters synchronously. This function blocks the main thread for the duration of the query, so use it with caution.
   * @param {lbug.PreparedStatement} preparedStatement the prepared statement
   * @param {Object} params a plain object mapping parameter names to values.
   * @returns {Array<lbug.QueryResult> | lbug.QueryResult} an array of query results. If there is only one query result, the function returns the query result directly.
   * @throws {Error} if there is an error.
   */
  executeSync(preparedStatement, params = {}) {
    if (
      !typeof preparedStatement === "object" ||
      preparedStatement.constructor.name !== "PreparedStatement"
    ) {
      throw new Error("preparedStatement must be a valid PreparedStatement object.");
    }
    if (!preparedStatement.isSuccess()) {
      throw new Error(preparedStatement.getErrorMessage());
    }
    if (params.constructor !== Object) {
      throw new Error("params must be a plain object.");
    }
    const paramArray = [];
    for (const key in params) {
      const value = params[key];
      paramArray.push([key, value]);
    }
    const connection = this._getConnectionSync();
    const nodeQueryResult = new LbugNative.NodeQueryResult();
    connection.executeSync(preparedStatement._preparedStatement, nodeQueryResult, paramArray);
    return this._unwrapMultipleQueryResultsSync(nodeQueryResult);
  }

  /**
   * Prepare a statement for execution.
   * @param {String} statement the statement to prepare.
   * @returns {Promise<lbug.PreparedStatement>} a promise that resolves to the prepared statement. The promise is rejected if there is an error.
   */
  prepare(statement) {
    return new Promise((resolve, reject) => {
      if (typeof statement !== "string") {
        return reject(new Error("statement must be a string."));
      }
      this._getConnection()
        .then((connection) => {
          const preparedStatement = new LbugNative.NodePreparedStatement(
            connection,
            statement
          );
          preparedStatement.initAsync((err) => {
            if (err) {
              return reject(err);
            }
            return resolve(new PreparedStatement(this, preparedStatement));
          });
        })
        .catch((err) => {
          return reject(err);
        });
    });
  }

  /**
   * Prepare a statement for execution synchronously. This function blocks the main thread so use it with caution.
   * @param {String} statement the statement to prepare. 
   * @returns {lbug.PreparedStatement} the prepared statement.
   * @throws {Error} if there is an error.
   */
  prepareSync(statement) {
    if (typeof statement !== "string") {
      throw new Error("statement must be a string.");
    }
    const connection = this._getConnectionSync();
    const preparedStatement = new LbugNative.NodePreparedStatement(
      connection,
      statement
    );
    preparedStatement.initSync();
    return new PreparedStatement(this, preparedStatement);
  }

  /**
   * Execute a query.
   * @param {String} statement the statement to execute.
   * @param {Function} [progressCallback] - Optional callback function that is invoked with the progress of the query execution. The callback receives three arguments: pipelineProgress, numPipelinesFinished, and numPipelines.
   * @returns {Promise<lbug.QueryResult>} a promise that resolves to the query result. The promise is rejected if there is an error.
   */
  query(statement, progressCallback) {
    return new Promise((resolve, reject) => {
      if (typeof statement !== "string") {
        return reject(new Error("statement must be a string."));
      }
      if (progressCallback && typeof progressCallback !== "function") {
        return reject(new Error("progressCallback must be a function."));
      }
      this._getConnection()
        .then((connection) => {
          const nodeQueryResult = new LbugNative.NodeQueryResult();
          try {
            connection.queryAsync(statement, nodeQueryResult, (err) => {
              if (err) {
                return reject(err);
              }
              this._unwrapMultipleQueryResults(nodeQueryResult)
                .then((queryResults) => {
                  return resolve(queryResults);
                })
                .catch((err) => {
                  return reject(err);
                });
            },
              progressCallback);
          } catch (e) {
            return reject(e);
          }
        })
        .catch((err) => {
          return reject(err);
        });
    });
  }

  /**
   * Execute a query synchronously.
   * @param {String} statement the statement to execute. This function blocks the main thread for the duration of the query, so use it with caution.
   * @returns {Array<lbug.QueryResult> | lbug.QueryResult} an array of query results. If there is only one query result, the function returns the query result directly.
   * @throws {Error} if there is an error.
   * @throws {Error} if the statement is not a string.
   * @throws {Error} if the connection is closed.
   */
  querySync(statement) {
    if (typeof statement !== "string") {
      throw new Error("statement must be a string.");
    }
    const connection = this._getConnectionSync();
    const nodeQueryResult = new LbugNative.NodeQueryResult();
    connection.querySync(statement, nodeQueryResult);
    return this._unwrapMultipleQueryResultsSync(nodeQueryResult);
  }

  /**
   * Internal function to get the next query result for multiple query results.
   * @param {LbugNative.NodeQueryResult} nodeQueryResult the current node query result.
   * @returns {Promise<lbug.QueryResult>} a promise that resolves to the next query result. The promise is rejected if there is an error.
   */
  _getNextQueryResult(nodeQueryResult) {
    return new Promise((resolve, reject) => {
      nodeQueryResult.getNextQueryResultAsync((err, nextNodeQueryResult) => {
        if (err) {
          return reject(err);
        }
        if (!nextNodeQueryResult) {
          return resolve(undefined);
        }
        return resolve(new QueryResult(this, nextNodeQueryResult));
      });
    });
  }

  /**
   * Internal function to unwrap multiple query results into an array of query results.
   * @param {LbugNative.NodeQueryResult} nodeQueryResult the node query result.
   * @returns {Promise<Array<lbug.QueryResult>> | lbug.QueryResult} a promise that resolves to an array of query results. The promise is rejected if there is an error.
   */
  async _unwrapMultipleQueryResults(nodeQueryResult) {
    const wrappedQueryResult = new QueryResult(this, nodeQueryResult);
    if (!nodeQueryResult.hasNextQueryResult()) {
      return wrappedQueryResult;
    }
    const queryResults = [wrappedQueryResult];
    let currentQueryResult = nodeQueryResult;
    while (currentQueryResult.hasNextQueryResult()) {
      queryResults.push(await this._getNextQueryResult(currentQueryResult));
      currentQueryResult = queryResults[queryResults.length - 1]._queryResult;
    }
    return queryResults;
  }

  /**
   * Internal function to unwrap multiple query results into an array of query results synchronously.
   * @param {LbugNative.NodeQueryResult} nodeQueryResult the node query result.
   * @returns {Array<lbug.QueryResult> | lbug.QueryResult} an array of query results.
   * @throws {Error} if there is an error.
   */
  _unwrapMultipleQueryResultsSync(nodeQueryResult) {
    const wrappedQueryResult = new QueryResult(this, nodeQueryResult);
    if (!nodeQueryResult.hasNextQueryResult()) {
      return wrappedQueryResult;
    }
    const queryResults = [wrappedQueryResult];
    let currentQueryResult = nodeQueryResult;
    while (currentQueryResult.hasNextQueryResult()) {
      const nextNodeQueryResult = currentQueryResult.getNextQueryResultSync();
      const nextQueryResult = new QueryResult(this, nextNodeQueryResult);
      queryResults.push(nextQueryResult);
      currentQueryResult = nextNodeQueryResult;
    }
    return queryResults;
  }

  /**
   * Set the maximum number of threads to use for query execution.
   * @param {Number} numThreads the maximum number of threads to use for query execution.
   */
  setMaxNumThreadForExec(numThreads) {
    // If the connection is not initialized yet, store the logging level
    // and defer setting it until the connection is initialized.
    if (typeof numThreads !== "number" || !numThreads || numThreads < 0) {
      throw new Error("numThreads must be a positive number.");
    }
    if (this._isInitialized) {
      this._connection.setMaxNumThreadForExec(numThreads);
    } else {
      this._numThreads = numThreads;
    }
  }

  /**
   * Set the timeout for queries. Queries that take longer than the timeout
   * will be aborted.
   * @param {Number} timeoutInMs the timeout in milliseconds.
   */
  setQueryTimeout(timeoutInMs) {
    if (
      typeof timeoutInMs !== "number" ||
      isNaN(timeoutInMs) ||
      timeoutInMs <= 0
    ) {
      throw new Error("timeoutInMs must be a positive number.");
    }
    if (this._isInitialized) {
      this._connection.setQueryTimeout(timeoutInMs);
    } else {
      this._queryTimeout = timeoutInMs;
    }
  }

  /**
   * Close the connection. 
   * 
   * Note: Call to this method is optional. The connection will be closed
   * automatically when the object goes out of scope.
   */
  async close() {
    if (this._isClosed) {
      return;
    }
    if (!this._isInitialized) {
      if (this._initPromise) {
        // Connection is initializing, wait for it to finish first.
        await this._initPromise;
      } else {
        // Connection is not initialized, simply mark it as closed and initialized.
        this._isInitialized = true;
        this._isClosed = true;
        delete this._connection;
        return;
      }
    }
    // Connection is initialized, close it.
    this._connection.close();
    delete this._connection;
    this._isClosed = true;
  }

  /**
   * Close the connection synchronously.
   * @throws {Error} if there is an undergoing asynchronous initialization.
   */
  closeSync() {
    if (this._isClosed) {
      return;
    }
    if (!this._isInitialized) {
      if (this._initPromise) {
        throw new Error("There is an ongoing asynchronous initialization. Please wait for it to finish.");
      }
      this._isInitialized = true;
      this._isClosed = true;
      delete this._connection;
      return;
    }
    this._connection.close();
    delete this._connection;
    this._isClosed = true;
  }
}

module.exports = Connection;
