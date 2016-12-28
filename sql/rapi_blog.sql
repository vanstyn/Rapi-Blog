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
  [full_name] varchar(64) UNIQUE NOT NULL
);
INSERT INTO [user] VALUES(0,'(system)','System User');

DROP TABLE IF EXISTS [preprocessor];
CREATE TABLE [preprocessor] (
  [code] varchar(8) PRIMARY KEY NOT NULL,
  [name] varchar(32) UNIQUE NOT NULL
);
INSERT INTO [preprocessor] VALUES('tt',  'Template Toolkit');


DROP TABLE IF EXISTS [format];
CREATE TABLE [format] (
  [code] varchar(8) PRIMARY KEY NOT NULL,
  [name] varchar(32) UNIQUE NOT NULL
  
);
INSERT INTO [format] VALUES('txt',  'Plain Text');
INSERT INTO [format] VALUES('md',   'Markdown');
INSERT INTO [format] VALUES('html', 'HTML');


DROP TABLE IF EXISTS [content];
CREATE TABLE [content] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [name] varchar(255) UNIQUE NOT NULL,
  [title] varchar(255) DEFAULT NULL,
  [create_ts] datetime NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP,'localtime')),
  [update_ts] datetime NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP,'localtime')),
  [create_user_id] INTEGER NOT NULL,
  [update_user_id] INTEGER NOT NULL,
  [pp_code] varchar(8) DEFAULT NULL,
  [format_code] varchar(8) DEFAULT NULL,
  [published] BOOLEAN NOT NULL DEFAULT 0,
  [publish_ts] datetime DEFAULT NULL,
  
  [body] text default '',
  
  
  FOREIGN KEY ([create_user_id]) REFERENCES [user]         ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([update_user_id]) REFERENCES [user]         ([id])   ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([pp_code])        REFERENCES [preprocessor] ([code]) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY ([format_code])    REFERENCES [format]       ([code]) ON DELETE RESTRICT ON UPDATE CASCADE
  
);


DROP TABLE IF EXISTS [keyword];
CREATE TABLE [keyword] (
  [name] varchar(64) PRIMARY KEY NOT NULL
);

DROP TABLE IF EXISTS [content_keyword];
CREATE TABLE [content_keyword] (
  [id] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  [content_id] INTEGER NOT NULL,
  [keyword_name] varchar(64) UNIQUE NOT NULL,
  
  FOREIGN KEY ([content_id])   REFERENCES [content] ([id])   ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ([keyword_name]) REFERENCES [keyword] ([name]) ON DELETE CASCADE ON UPDATE CASCADE
  
);



