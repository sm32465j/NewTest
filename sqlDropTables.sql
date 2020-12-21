Declare @sql as varchar(4000)
Declare @tableName as varchar(400)
Declare @tableType as varchar(400)
Set @sql = ''
Set @tableName = ''
Set @tableType = ''


Declare cview cursor for
	Select table_name
	from information_schema.tables
	where 
	table_name <>'acesXMLfiles'			and 
	table_type = 'view' 

Open cview
Fetch next from cview into @tablename

while @@fetch_status = 0
begin
	Set @sql ='Drop view ' + @tablename

	execute(@sql)
	Fetch next from cview into @tablename
end

close cview
deallocate cview


---now tables
Declare ctable cursor for
	Select table_name
	from information_schema.tables
	where 
	table_name <>'acesXMLfiles'			and 
	table_type = 'base table' 

Open ctable
Fetch next from ctable into @tablename

while @@fetch_status = 0
begin
	Set @sql ='Drop table ' + @tablename

	execute(@sql)
	Fetch next from ctable into @tablename
end

close ctable
deallocate ctable

