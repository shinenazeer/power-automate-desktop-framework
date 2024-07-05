CREATE PROCEDURE [dbo].[usp_InsertWorkItemResult]
    @WorkItemId BIGINT,
    @MachineName NVARCHAR(MAX),
	@ProjectNumber NVARCHAR(50),
    @FlowName NVARCHAR(MAX),
    @WorkItemStatus NVARCHAR(255),
    @WorkItemReason NVARCHAR(255),
    @WorkItemMessage NVARCHAR(MAX),
    @ProcessingStartUTC DATETIMEOFFSET(3)

AS
BEGIN
    DECLARE @Status SMALLINT
            ,@Message NVARCHAR(MAX)
    BEGIN TRY
        BEGIN TRANSACTION
        SET NOCOUNT ON
        -- on stored procedure fatal, rollbacks transaction so it is not kept alive
        SET XACT_ABORT ON

        DECLARE @Result INT
                ,@StatusId SMALLINT
				,@ProjectId SMALLINT
                ,@FlowId SMALLINT
                ,@MachineId SMALLINT
                ,@ProcessingEndUTC DATETIMEOFFSET(3)
                ,@InsertedAtUTC DATETIMEOFFSET(3)
                ,@UpdatedAtUTC DATETIMEOFFSET(3)
        -- try to lock stored procedure exclusively, wait for 30s
        EXEC @Result = sp_getapplock @Resource = 'usp_InsertWorkItemResult', @LockMode = 'Exclusive', @LockTimeout = 30000, @LockOwner = 'Transaction'

        IF @Result < 0
        BEGIN
            SET @Status = -2
            SET @Message = N'Failed to lock stored procedure usp_InsertWorkItemResult exclusively'
            ;THROW 51000, @Message, 1
        END

        SET @InsertedAtUTC = [dbo].[ufn_GetUTCDate]()
        SET @UpdatedAtUTC = @InsertedAtUTC
        SET @ProcessingEndUTC = @InsertedAtUTC

		SET @ProjectId = [dbo].[ufn_GetProjectId](@ProjectNumber)

		IF @ProjectId IS NULL
        BEGIN
            SET @Status = -3
            SET @Message = N'Project with project number ' + @ProjectNumber + ' does not exist in Project table'
            ;THROW 51000, @Message, 1
        END

        SET @StatusId = [dbo].[ufn_GetStatusId](@WorkItemStatus)
        SET @FlowId = [dbo].[ufn_GetFlowId](@FlowName, @ProjectId)
        SET @MachineId = [dbo].[ufn_GetMachineId](@MachineName)

        IF NOT EXISTS (SELECT TOP(1) wi.[Id] FROM [WorkItem] wi WHERE wi.[Id] = @WorkItemId)
        BEGIN
            SET @Status = -4
            SET @Message = N'Could not find work item id with id ' + CAST(@WorkItemId AS NVARCHAR) + ' in WorkItem table'
            ;THROW 51000, @Message, 1
        END
        ELSE IF @StatusId IS NULL
        BEGIN
            SET @Status = -5
            SET @Message = N'Could not find status id with name ' + @WorkItemStatus + ' in Status table'
            ;THROW 51000, @Message, 1
        END
        ELSE IF @FlowId IS NULL
        BEGIN
            SET @Status = -6
            SET @Message = N'Could not find Flow id with name ' + @FlowName + ' in Flow table'
            ;THROW 51000, @Message, 1
        END
        ELSE IF @MachineId IS NULL
        BEGIN
            SET @Status = -7
            SET @Message = N'Could not find machine id with name ' + @MachineName + ' in Machine table'
            ;THROW 51000, @Message, 1
        END

        -- remove lock and machine so work item can get picked up again on failure
        UPDATE [WorkItem]
        SET
            [StatusId] = @StatusId,
            [MachineId] = NULL,
            [UpdatedAtUTC] = @UpdatedAtUTC
        WHERE
            [Id] = @WorkItemId

        INSERT INTO [WorkItemResult] (WorkItemId, StatusId, MachineId, FlowId, Reason, Message, ProcessingStartUTC, ProcessingEndUTC, InsertedAtUTC)
        VALUES
        (@WorkItemId, @StatusId, @MachineId, @FlowId, @WorkItemReason, @WorkItemMessage, @ProcessingStartUTC, @ProcessingEndUTC, @InsertedAtUTC)

        SET @Status = 0
        SET @Message = N'Successfully inserted work item result for work item id ' + CAST(@WorkItemId AS NVARCHAR)

        COMMIT TRANSACTION

        SELECT @Status 'Status', @Message 'Message'
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION
        END

        IF @Status IS NULL
        BEGIN
            SET @Status = -1
        END

        SELECT @Status 'Status', ERROR_MESSAGE() 'Message'
    END CATCH
END