import lbug from "./index.js";

// Re-export everything from the CommonJS module
export const Database = lbug.Database;
export const Connection = lbug.Connection;
export const PreparedStatement = lbug.PreparedStatement;
export const QueryResult = lbug.QueryResult;
export const VERSION = lbug.VERSION;
export const STORAGE_VERSION = lbug.STORAGE_VERSION;
export default lbug;
