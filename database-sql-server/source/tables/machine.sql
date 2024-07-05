CREATE TABLE Machine
(
    [Id] SMALLINT PRIMARY KEY IDENTITY(1, 1) NOT NULL,
    [Name] NVARCHAR(MAX) NOT NULL,
    [Environments] NVARCHAR(255) NOT NULL,
    [InsertedAtUTC] DATETIMEOFFSET(3) NOT NULL DEFAULT TODATETIMEOFFSET(GETUTCDATE(), 0),
    [UpdatedAtUTC] DATETIMEOFFSET(3) NOT NULL DEFAULT TODATETIMEOFFSET(GETUTCDATE(), 0)
)