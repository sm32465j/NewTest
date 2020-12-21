Create view vw_adBvidPartPartterm
	with schemabinding
	as
	Select 
		bvid.header_id	as header_id,
		bvid.App_Id		as app_id,
		bvid.id			as baseVehicleID,
		p.[text]		as PartNo,
		pt.id			as partermID
	from 
	dbo.Basevehicle					bvid 
	join 
	dbo.part						p 
	on 
	bvid.header_id = p.header_id	and 
	bvid.app_id = p.app_id 
	join 
	dbo.PartType					pt 
	on 
	bvid.header_id = pt.header_id	and 
	bvid.App_Id = pt.App_Id
	;
Go
Create unique clustered index idx_vw_adBvidPartPartterm on vw_adBvidPartPartterm (header_id asc, app_id asc);



