--Declare @list	varchar(max)  ='BrakeABS:BrakeSystem:CylinderHeadType:DriveType:EngineBase:EngineBlock:EngineBoreStroke:EngineDesignation:EngineMfr:EngineVersion'
Declare @list	varchar(max)  ='ab'
Declare @action varchar(max)  ='d'



if object_id('gtt.dbo.gtt_ObjectID')	is null
	Begin
		Create table gtt.dbo.gtt_ObjectID(
			objectID	integer		not null
			);
		Create unique clustered index pk_gtt_tables on gtt.dbo.gtt_ObjectID(objectID asc)
	end
Else truncate table gtt.dbo.gtt_ObjectID;

	 if @list = 'ab' 
insert into gtt.dbo.gtt_ObjectID(objectID) 
	----------------------------
	Select object_id from sys.objects where [type] in ('u','v')
else if @list = 'at'
insert into gtt.dbo.gtt_ObjectID(objectID) 
	----------------------------
	Select object_id from sys.objects where [type] in ('u')
else if @list = 'av'
insert into gtt.dbo.gtt_ObjectID(objectID) 
	----------------------------
	Select object_id from sys.objects where [type] in ('v')
else
insert into gtt.dbo.gtt_ObjectID(objectID) 
	----------------------------
	Select object_id from 
	sys.objects									s
	join 
	spfnvw.dbo.fn_Parse_words(@list,':',null)	pn
	on pn.word = s.name


if object_id('tempdb.dbo.#tmpProcessOrder')	is null
	Begin
		Create table #tmpProcessOrder(
			procOrder		integer identity,
			objectNumber	integer				not null,
			primary key(objectNumber asc) with (ignore_dup_key = on)
			);
	end
Else 
	begin
		truncate table #tmpProcessOrder
		dbcc checkident('#tmpProcessOrder', reseed, 1)
	end;



With base(childid,lvl,parentid) as
(
	Select distinct
		o.object_id			as id, 
		0					as lvl, 
		d.referenced_id		as parentid
	from sys.objects						o
	left join 	
	sys.sql_expression_dependencies			d
	on o.object_id = d.referenced_id
	where 
	o.[type] not in ('s','it','p','sq')	and
	d.referenced_id is null
	Union all
	select 
		d1.referenced_id		as ChildID,
		p.lvl + 1				as lvl,
		d1.referencing_id		as parentID
	from sys.sql_expression_dependencies	d1
	inner join base as p on d1.referencing_id = p.childid
)
Insert into #tmpProcessOrder(objectNumber)
	-------------
	Select Distinct childid 
	from (---Needed for the order by clause in the inline
		  Select top(100)percent childid 
		  from 
		  base 
		  order by lvl --desc
		  ) as il  join sys.objects so on il.childid = so.object_id join gtt.dbo.gtt_ObjectID oid on so.parent_object_id = oid.objectID
		  where childid is not null
	 option(maxrecursion 32767);


Insert into #tmpProcessOrder(objectNumber)
	-------------
	Select object_id from sys.objects s join gtt.dbo.gtt_ObjectID oid on s.object_id = oid.objectID


Declare @tablename	as varchar(400)
Declare @parentName	as varchar(400)
Declare @tabletype	as varchar(400)
Declare @sql		as varchar(400)

Declare cControl cursor for
	Select 
		s.name						as tablename,
		isnull(parent.name,'')		as parentName,
		s.[type]					as tabletype
	from 
	sys.objects				s 
	left join 
	sys.objects				Parent
	on s.parent_object_id = parent.object_id
	join
	#tmpProcessOrder		t 
	on s.object_id = t.objectNumber 
	order by t.procOrder

Open cControl
Fetch next from cControl into @tablename,@parentName,@tabletype

while @@fetch_status = 0
	begin
		If @tabletype = 'v' 
			Set @sql ='Drop view '  + @tablename
		Else if @tabletype ='u' 
			Set @sql ='Drop table ' + @tablename
		Else if @tabletype ='f' 
			Set @sql ='Alter table ' + @parentName + ' drop constraint ' + @tablename

		execute(@sql)

		Fetch next from cControl into @tablename,@parentName,@tabletype
	end

close cControl
deallocate cControl


