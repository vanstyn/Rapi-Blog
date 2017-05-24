--------------------------------------------------------------------------------
--   *** sql/rapi_blog.sql  --  DO NOT MOVE OR RENAME THIS FILE ***
-- 
-- Add your DDL here (i.e. CREATE TABLE statements)
-- 
-- To (re)initialize your SQLite database (rapi_blog.db) and (re)generate
-- your DBIC schema classes and update your base TableSpec configs, run this command
-- from your app home directory:
-- 
--    perl devel/model_DB_updater.pl --from-ddl --cfg
-- 
--------------------------------------------------------------------------------


DROP TABLE IF EXISTS [user];
CREATE TABLE [user] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [username] varchar(32) UNIQUE NOT NULL,
  [full_name] varchar(64) UNIQUE DEFAULT NULL,
  [admin] BOOLEAN NOT NULL DEFAULT 0,
  [author] BOOLEAN NOT NULL DEFAULT 0,
  [comment] BOOLEAN NOT NULL DEFAULT 1
);
INSERT INTO [user] VALUES(0,'(system)','System User',1,1,1);


DROP TABLE IF EXISTS [post];
CREATE TABLE [post] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(255) UNIQUE NOT NULL,
  [title] varchar(255) DEFAULT NULL,
  [image] varchar(255) DEFAULT NULL,
  [ts] datetime NOT NULL,
  [create_ts] datetime NOT NULL,
  [update_ts] datetime NOT NULL,
  [author_id] INTEGER NOT NULL,
  [creator_id] INTEGER NOT NULL,
  [updater_id] INTEGER NOT NULL,
  [published] BOOLEAN NOT NULL DEFAULT 0,
  [publish_ts] datetime DEFAULT NULL,
  [size] INTEGER DEFAULT NULL,
  [body] text default '',
  
  FOREIGN KEY ([author_id]) REFERENCES [user]              ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([creator_id]) REFERENCES [user]             ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([updater_id]) REFERENCES [user]             ([id])   ON DELETE RESTRICT ON UPDATE CASCADE
  
);


DROP TABLE IF EXISTS [keyword];
CREATE TABLE [keyword] (
  [name] varchar(64) PRIMARY KEY NOT NULL
);

DROP TABLE IF EXISTS [post_keyword];
CREATE TABLE [post_keyword] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [post_id] INTEGER NOT NULL,
  [keyword_name] varchar(64) UNIQUE NOT NULL,
  
  FOREIGN KEY ([post_id])      REFERENCES [post] ([id])      ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([keyword_name]) REFERENCES [keyword] ([name]) ON DELETE CASCADE ON UPDATE CASCADE
  
);



