create procedure sp_upLoadFileDetail
	@hid  integer, @limitElements varchar(4000) = null
	as
Begin
	Declare @transaction	as varchar(300);
	Set @transaction = 'Transaction_' +cast(@hid as varchar(30))

	if object_id('gtt.dbo.gtt_limitElement') is null
		Begin 
			Create table gtt.dbo.gtt_limitElement(
				Element varchar(60)		not null,
				primary key (element asc) with(ignore_dup_key =on)
				)
		end
	else truncate table gtt.dbo.gtt_limitElement;

	Begin transaction @transaction ;
		Declare @element as varchar(300);

		Declare @xml		xml---(xsdAces4)  --need to read in the 3.01 xsd
		Select @xml = acesXMLFile from acesXMLfiles where header_id = @hid;	


		if @limitElements is null
			Declare ProcessElements cursor for 
				Select element from vw_ElementsPresentByHeaderID where header_id = @hid
		else
			Declare ProcessElements cursor for 
				Select 
					element 
				from 
				vw_ElementsPresentByHeaderID							v 
				join 
				ProcFuncViews.dbo.fn_Parse_words(@limitElements,':',null)	l 
				on v.element = l.word 
				where header_id = @hid

		Open ProcessElements

		Fetch next from ProcessElements into @element

		while @@fetch_status = 0
		begin
			print @element
			execute dbo.sp_upLoadxmlElement @hid,@xml,@element

			Fetch next from ProcessElements into @element
		end

		Close ProcessElements
		deallocate ProcessElements
	Commit Transaction @transaction;

end
