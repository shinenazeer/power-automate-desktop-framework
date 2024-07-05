CREATE TABLE Credential
(
    [Id] SMALLINT PRIMARY KEY IDENTITY(1, 1) NOT NULL,
    [Name] NVARCHAR(MAX) NOT NULL,
    [Username] NVARCHAR(MAX) NOT NULL,
    [HashedPassword] NVARCHAR(MAX) NOT NULL,
    [ReadOnly] BIT NOT NULL,
    [InsertedAtUTC] DATETIMEOFFSET(3) NOT NULL DEFAULT TODATETIMEOFFSET(GETUTCDATE(), 0),
    [UpdatedAtUTC] DATETIMEOFFSET(3) NOT NULL DEFAULT TODATETIMEOFFSET(GETUTCDATE(), 0)
)