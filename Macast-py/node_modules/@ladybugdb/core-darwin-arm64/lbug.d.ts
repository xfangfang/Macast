
/**
 * A nullable type that can be either T or null.
 */
export type Nullable<T> = T | null;

/**
 * A callback function pattern used throughout the API.
 * @template T The type of the result value (defaults to void)
 */
export type Callback<T = void> = (error: Error | null, result?: T) => void;

/**
 * Callback for query execution progress updates.
 * @param pipelineProgress Progress of the current pipeline (0-100)
 * @param numPipelinesFinished Number of pipelines completed
 * @param numPipelines Total number of pipelines
 */
export type ProgressCallback = (
    pipelineProgress: number,
    numPipelinesFinished: number,
    numPipelines: number
) => void;

/**
 * Represents a node ID in the graph database.
 */
export interface NodeID {
    /** The offset of the node in its table */
    offset: number;
    /** The table ID the node belongs to */
    table: number;
}

/**
 * Represents a node value in the graph.
 */
export interface NodeValue {
    /** The label of the node (type) */
    _label: string | null;
    /** The ID of the node */
    _id: NodeID | null;
    /** Additional properties of the node */
    [key: string]: any;
}

/**
 * Represents a relationship (edge) value in the graph.
 */
export interface RelValue {
    /** The source node ID */
    _src: NodeID | null;
    /** The destination node ID */
    _dst: NodeID | null;
    /** The relationship type/label */
    _label: string | null;
    /** The relationship ID */
    _id: any;
    /** Additional properties of the relationship */
    [key: string]: any;
}

/**
 * Represents a recursive relationship value (path) in the graph.
 */
export interface RecursiveRelValue {
    /** Array of nodes in the path */
    _nodes: any[];
    /** Array of relationships in the path */
    _rels: any[];
}

/**
 * Union type representing all possible value types in Lbug.
 */
export type LbugValue =
    | null
    | boolean
    | number
    | bigint
    | string
    | Date
    | NodeValue
    | RelValue
    | RecursiveRelValue
    | LbugValue[]
    | { [key: string]: LbugValue };

/**
 * Configuration options for the database system.
 */
export interface SystemConfig {
    /** Size of the buffer pool in bytes */
    bufferPoolSize?: number;
    /** Whether to enable compression */
    enableCompression?: boolean;
    /** Whether to open the database in read-only mode */
    readOnly?: boolean;
    /** Maximum size of the database in bytes */
    maxDBSize?: number;
    /** Whether to enable automatic checkpoints */
    autoCheckpoint?: boolean;
    /** Threshold for automatic checkpoints */
    checkpointThreshold?: number;
}

/**
 * Represents a Lbug database instance.
 */
export class Database {
    /**
     * Constructs a new Database instance.
     * @param databasePath Path to the database directory (defaults to ":memory:")
     * @param bufferManagerSize Size of the buffer manager in bytes
     * @param enableCompression Whether to enable compression
     * @param readOnly Whether to open in read-only mode
     * @param maxDBSize Maximum size of the database in bytes
     * @param autoCheckpoint Whether to enable automatic checkpoints
     * @param checkpointThreshold Threshold for automatic checkpoints
     */
    constructor(
        databasePath?: string,
        bufferManagerSize?: number,
        enableCompression?: boolean,
        readOnly?: boolean,
        maxDBSize?: number,
        autoCheckpoint?: boolean,
        checkpointThreshold?: number
    );

    /**
     * Initialize the database. Calling this function is optional, as the
     * database is initialized automatically when the first query is executed.
     * @returns Promise that resolves when initialization completes
     */
    init(): Promise<void>;

    /**
     * Initialize the database synchronously. Calling this function is optional, as the
     * database is initialized automatically when the first query is executed. This function
     * may block the main thread, so use it with caution.
     */
    initSync(): void;

    /**
     * Close the database and release resources.
     * @returns Promise that resolves when database is closed
     */
    close(): Promise<void>;

    /**
     * Close the database synchronously.
     */
    closeSync(): void;

    /**
     * Get the version of the Lbug library.
     * @returns The version string of the library
     */
    static getVersion(): string;

    /**
     * Get the storage version of the Lbug library.
     * @returns The storage version of the library
     */
    static getStorageVersion(): number;
}

/**
 * Represents a connection to a Lbug database.
 */
export class Connection {
    /**
     * Creates a new connection to the specified database.
     * @param database The database instance to connect to
     * @param numThreads Optional maximum number of threads for query execution
     */
    constructor(database: Database, numThreads?: number);

    /**
     * Initialize the connection.
     * @returns Promise that resolves when initialization completes
     */
    init(): Promise<void>;

    /**
     * Initialize the connection synchronously. This function may block the main thread, so use it with caution.
     */
    initSync(): void;

    /**
     * Set the maximum number of threads for query execution.
     * @param numThreads The number of threads to use
     */
    setMaxNumThreadForExec(numThreads: number): void;

    /**
     * Set the query timeout in milliseconds.
     * @param timeoutInMs Timeout in milliseconds
     */
    setQueryTimeout(timeoutInMs: number): void;

    /**
     * Close the connection.
     * @returns Promise that resolves when connection is closed
     */
    close(): Promise<void>;

    /**
     * Close the connection synchronously.
     */
    closeSync(): void;

    /**
     * Execute a prepared statement.
     * @param preparedStatement The prepared statement to execute
     * @param params Parameters for the query as a plain object
     * @param progressCallback Optional progress callback
     * @returns Promise that resolves to the query result(s)
     */
    execute(
        preparedStatement: PreparedStatement,
        params?: Record<string, LbugValue>,
        progressCallback?: ProgressCallback
    ): Promise<QueryResult | QueryResult[]>;

    /**
     * Execute a prepared statement synchronously.
     * @param preparedStatement The prepared statement to execute
     * @param params Parameters for the query as a plain object
     * @returns The query result(s)
     */
    executeSync(
        preparedStatement: PreparedStatement,
        params?: Record<string, LbugValue>
    ): QueryResult | QueryResult[];

    /**
     * Prepare a statement for execution.
     * @param statement The statement to prepare
     * @returns Promise that resolves to the prepared statement
     */
    prepare(statement: string): Promise<PreparedStatement>;

    /**
     * Prepare a statement for execution synchronously.
     * @param statement The statement to prepare
     * @returns The prepared statement
     */
    prepareSync(statement: string): PreparedStatement;

    /**
     * Execute a query.
     * @param statement The statement to execute
     * @param progressCallback Optional progress callback
     * @returns Promise that resolves to the query result(s)
     */
    query(
        statement: string,
        progressCallback?: ProgressCallback
    ): Promise<QueryResult | QueryResult[]>;

    /**
     * Execute a query synchronously.
     * @param statement The statement to execute
     * @returns The query result(s)
     */
    querySync(statement: string): QueryResult | QueryResult[];
}

/**
 * Represents a prepared statement for efficient query execution.
 * Note: This class is created internally by Connection.prepare() methods.
 */
export class PreparedStatement {
    /**
     * Check if the statement was prepared successfully.
     * @returns True if preparation was successful
     */
    isSuccess(): boolean;

    /**
     * Get the error message if preparation failed.
     * @returns The error message or empty string if successful
     */
    getErrorMessage(): string;
}

/**
 * Represents the results of a query execution.
 * Note: This class is created internally by Connection query methods.
 */
export class QueryResult {
    /**
     * Reset the iterator for reading results.
     */
    resetIterator(): void;

    /**
     * Check if there are more rows to read.
     * @returns True if more rows are available
     */
    hasNext(): boolean;

    /**
     * Get the number of tuples (rows) in the result.
     * @returns The number of rows
     */
    getNumTuples(): number;

    /**
     * Get the next row.
     * @returns Promise that resolves to the next row or null if no more rows
     */
    getNext(): Promise<Record<string, LbugValue> | null>;

    /**
     * Get the next row synchronously.
     * @returns The next row or null if no more rows
     */
    getNextSync(): Record<string, LbugValue> | null;

    /**
     * Iterate through the query result with callback functions.
     * @param resultCallback Callback function called for each row
     * @param doneCallback Callback function called when iteration is done
     * @param errorCallback Callback function called when there is an error
     */
    each(
        resultCallback: (row: Record<string, LbugValue>) => void,
        doneCallback: () => void,
        errorCallback: (error: Error) => void
    ): void;

    /**
     * Get all rows of the query result.
     * @returns Promise that resolves to all rows
     */
    getAll(): Promise<Record<string, LbugValue>[]>;

    /**
     * Get all rows of the query result synchronously.
     * @returns All rows of the query result
     */
    getAllSync(): Record<string, LbugValue>[];

    /**
     * Get all rows of the query result with callback functions.
     * @param resultCallback Callback function called with all rows
     * @param errorCallback Callback function called when there is an error
     */
    all(
        resultCallback: (rows: Record<string, LbugValue>[]) => void,
        errorCallback: (error: Error) => void
    ): void;

    /**
     * Get the column data types.
     * @returns Promise that resolves to array of data type strings
     */
    getColumnDataTypes(): Promise<string[]>;

    /**
     * Get the column data types synchronously.
     * @returns Array of data type strings
     */
    getColumnDataTypesSync(): string[];

    /**
     * Get the column names.
     * @returns Promise that resolves to array of column names
     */
    getColumnNames(): Promise<string[]>;

    /**
     * Get the column names synchronously.
     * @returns Array of column names
     */
    getColumnNamesSync(): string[];

    /**
     * Close the result set and release resources.
     */
    close(): void;
}

/**
 * Default export for the Lbug module.
 */
declare const lbug: {
    Database: typeof Database;
    Connection: typeof Connection;
    PreparedStatement: typeof PreparedStatement;
    QueryResult: typeof QueryResult;
    VERSION: string;
    STORAGE_VERSION: bigint;
};

export default lbug;
