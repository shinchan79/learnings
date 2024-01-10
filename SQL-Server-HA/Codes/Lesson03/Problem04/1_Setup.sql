:setvar Publisher "Neptune\SQL2016"
:setvar Subscriber "Neptune\SQL2014"
:setvar DatabaseName "AdventureWorks"

:CONNECT $(Subscriber)



USE $(DatabaseName)


DELETE FROM [Sales].[Store]
WHERE [Name]='Next-Door Bike Store'

GO



:CONNECT $(Publisher)


USE $(DatabaseName)

GO

UPDATE [Sales].[Store]
	SET [SalesPersonID] = 276
	WHERE [Name]='Next-Door Bike Store'
	

