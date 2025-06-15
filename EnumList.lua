--[[------------------------------------------------------------------------------------------------------------------------
 
	--- EnumList Module ---	
	
	Created by Lincoln Touw
	V1.0 6/9/2025	 	 			
	
	--- LJPackageManager Information: ---	 
	<ModuleName>EnumList</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>1.0</ModuleVersion>	
	<PackageDependencies></PackageDependencies>	 			
	
--]]------------------------------------------------------------------------------------------------------------------------
 
export type EnumList = {
	GetName: (self) -> string,
	GetEnumItems: (self) -> { EnumListItem }, 	
	GetEnumNames: (self) -> { string },
	FromName: (self, name: string) -> EnumListItem?,
	FromValue: (self, value: number) -> EnumListItem?, 
};     	
export type TrashedEnumList = EnumList?;  

export type EnumListItem = {
	Value: number,
	Name: string,
	EnumType: string,
	Identifier: string,
	IsA: (_: string) -> boolean,
	GetEnumList: () -> EnumList,	 
}; 

export type EnumCollection = { string: EnumList }; 

----------------------------------------------------------------------------------------------------------------------------

local EnumCollection: { EnumList } = {};  	

local EnumList = {};         
EnumList.__index = EnumList;	

local EnumListItem = {};	
EnumListItem.__index = EnumListItem;

----------------------------------------------------------------------------------------------------------------------------

-- Creates a new <code>EnumListItem</code>.	 
-- <strong>Value</strong>: The numeric value of the <code>EnumListItem</code>.
-- <strong>Name</strong>: The name of the <code>EnumListItem</code>.
-- <strong>EnumType</strong>: The parent <code>EnumList</code>.
-- <strong>ListName</strong>: The name of the parent <code>EnumList</code>.
EnumListItem.new = function(Value: number, Name: string, EnumType: EnumList, ListName: string): EnumListItem  
	local this: EnumListItem = setmetatable(
		{ Value = Value, Name = Name, EnumType = ListName, Identifier = `EnumLists.{ListName}.{Name}({Value})`, },
		(EnumListItem)	
	);	        
	return this;	 	
end;	 
EnumList.__type = 'EnumListItem';	

-- Checks if the object belongs to a certain class.	 
function EnumListItem:IsClass(class: string): boolean
	assert(typeof(class) == 'string', 'Missing argument 1');	 
	return (getmetatable(self).__type == class);	
end;		 

EnumListItem.__call = function(this: EnumListItem,	...): ()
	return EnumListItem.Value; 
end;		 

EnumListItem.__eq = function(value1: EnumListItem, value2: EnumListItem): boolean	
	local m1, m2 = (getmetatable(value1) or {}), (getmetatable(value2) or {});	 	
	if (m1.__type ~= 'EnumListItem') or (m2.__type ~= 'EnumListItem') then
		error("Cannot compare EnumListItem with a different type", 0); 		
	end;	
	return value1.Identifier == value2.Identifier;		
end;		

EnumListItem.__tostring = function(value1: EnumListItem): string? 	
	return `EnumList.{value1.EnumType}.{value1.Name}`;		
end;	 

-- Checks if the <code>EnumListItem</code> belongs to an <code>EnumList</code> with the specified name.
-- <strong>enumListType</strong>: The name of the <code>EnumList</code> to check.	
function EnumListItem:IsA(enumListType: string): boolean
	return (self.EnumType == enumListType);	 
end;	 				

-- Returns the parent <code>EnumList</code> object.	 
function EnumListItem:GetEnumList(): EnumList		 
	return EnumCollection[self.EnumType];	 	
end;
 
----------------------------------------------------------------------------------------------------------------------------

-- Creates a new <code>EnumList</code> object.	 
-- <strong>name</strong>: The name of the EnumList.
-- <strong>items</strong>: An array containing strings that will create <code>EnumListItem</code>s.
EnumList.new = function(name: string, items: { string }): EnumList?  	
	--if RunService:IsClient() then 	 	
	--	if not script:GetAttribute'ServerInitiated' then
	--	warn('EnumList module has not yet been initiated on the server, and therefore cannot sync lists.')		
	--	else
	--	return CommSync:InvokeServer(name, items);
	--	end;	 
	--end;			
	assert(typeof(name) == 'string', '"name" parameter must be a valid string.');
	assert(typeof(items) == 'table', '"items" parameter must be a valid array.');  
	assert(#items > 0, '"items" parameter must contain at least 1 entry.');		
	if EnumCollection[name] then return error(`EnumList "{name} already exists, try invoking List:Delete first."`); end; 
	local enumItems = {}; 
	local meta = EnumList;		   	 	
	local list: EnumList = setmetatable({}, meta);	
	for index: number, value: string in items do
		assert(typeof(value) == 'string', '"items" parameter must be a dictionary containing only strings.');  
		enumItems[value] = setmetatable(EnumListItem.new(index, value, list, name), EnumListItem);               	 
	end;   		
	for index: string, value: EnumListItem in enumItems do
		if list[index] then return error(`Cannot assign "{index}"`); end;       
		list[index] = value;  
	end;      
	table.freeze(list);  
	EnumCollection[name] = list;  
	return list;    
end;       	
EnumList.__type = 'EnumList';
 
EnumList.__len = function(value1: EnumList): number?	 	
	local length = 0;			  		
	for index: string, value: EnumListItem in value1 do length += 1; end;	 			
	return length;	 	
end;		

EnumList.__tostring = function(value1: EnumList): string?	 		
	return `EnumList.{value1:GetName()}`;
end;	

EnumList.__call = function(this: EnumList, name: string?): (EnumListItem | { EnumListItem })? 	
	if not this:IsClass('EnumList') then return; end;
	return 
		if (name ~= nil) then this[name]	else this:GetEnumItems(); 	
end;	

-- Checks if an object belongs to a certain class.	
function EnumList:IsClass(class: string): boolean
	assert(typeof(class) == 'string', 'Missing argument 1');	 
	return (getmetatable(self).__type == class);	
end;		
	 
-- Returns the name of the <code>EnumList</code>.
function EnumList:GetName(): string? 	
	return EnumList:GetEnumItems()[1].EnumType;	 
end;

-- Returns an array of <code>EnumListItem</code>s that belong to the <code>EnumList</code>. 	
function EnumList:GetEnumItems(): { EnumListItem }	 	
	local form: { EnumListItem } = {};	 
	for index: string, value: EnumListItem in self do table.insert(form, value); end;	 
	return form;
end;	 

-- Returns an array containing the names of all <code>EnumListItem</code>s in an <code>EnumList</code>.	 
function EnumList:GetEnumNames(): { string }
	local form: { string } = {};
	for index: string, value: EnumListItem in self:GetEnumItems() do table.insert(form, index); end;
	return form;
end; 

-- Returns an <code>EnumListItem</code> whose name matches the provided <code>value</code>.
function EnumList:FromName(value: string): EnumListItem?
	return self:GetEnumItems()[value];  
end; 

-- Returns an <code>EnumListItem</code> whose numeric value matches the provided <code>value</code>. 	
function EnumList:FromValue(value: number): EnumListItem?
	for index: string, item: EnumListItem in self:GetEnumItems() do
		if item.Value == value then return item; end;
	end;
end;      

-- Removes the <code>EnumList</code>, and returns a copy of it containing only <code>EnumListItem</code>s and no methods.   
-- <strong>muteWarnings</strong>: Determines if the function shouldn't print any warnings.
function EnumList:Delete(muteWarnings: boolean?): TrashedEnumList   
	local name: string = self:GetName();	 
	EnumCollection[name] = nil;	 	  
	for index: string, value: EnumListItem | () -> {} in self do
		if typeof(value) == 'function' then self[index] = nil; end;
	end;      
	if not muteWarnings then
		warn(`Successfully deleted EnumList "{name}". It will no longer be usable by any other functions, scripts, etc. It can still be used as a reference in the scope that invoked the Delete function.`);        
	end;   
	return self;		 
end;

----------------------------------------------------------------------------------------------------------------------------

local Return = {};	

-- Returns an <code>EnumList</code> with the given name. If one does not exist, it will throw an error.
-- NOTE: To avoid errors, assign the "mute" attribute to true, which will return nil instead.
function Return:GetEnumList(name: string, mute: boolean): EnumList?                   
	local query: EnumList? = EnumCollection[name];	 	
	if query then return query; end;
	if mute then
		warn(`"{name}" is not a valid EnumList`); 	
		return;
	else
		return error(`"{name}" is not a valid EnumList`);		 
	end; 
end;    
 
-- Returns a dictionary containing every <code>EnumList</code> created under this DataModel.	 
function Return:GetEnumLists(): ({ EnumList } | EnumCollection)?		 
	--local form: { EnumList } = {};
	--for index: string, value: EnumList in EnumCollection do table.insert(form, value); end;
	return EnumCollection;	
end;	

Return.new = EnumList.new;	 	

return Return;     

----------------------------------------------------------------------------------------------------------------------------