--[[------------------------------------------------------------------------------------------------------------------------
 
	--- Errors Module ---	
	
	Created by Lincoln Touw 
	V1.1 6/17/2025 	
	V1.0 6/17/2025 			
	
	---------------------
	
	## LJPM created by Lincoln Touw 6/03/2025	
	## https://lincolntouw.github.io/ljpm-rbx			
	
	--- LJPackageManager Information: --- 
	<ModuleName>BetterErrors</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>1.1</ModuleVersion>			
	<PackageDependencies> 
		<Package>
			<Name>BetterTable</Name>
			<Version>1.0</Version>		
		</Package>
	</PackageDependencies>	 			
	 		
--]]------------------------------------------------------------------------------------------------------------------------
 			
-- # Type Declarations
export type Error = { Message: string, Code: number?, Trace: string?, Context: ({} | nil)?, 
	new: (Message: string, Code: number?, Context: {} | nil) -> Error?, };		  		
export type TypeError = Error & { Expected: string, Got: string };	 
export type NilError = Error & { Variable: string };
export type DependencyError = Error & { Missing: string };
export type PermissionError = Error & { Resource: string?, ExpectedLevel: number?, GotLevel: number? };		 
export type NetworkError = Error & { Expected: Enum.RunContext, Got: Enum.RunContext };
export type FormatError = Error;
export type ConcurrencyError = Error;
export type ParseError = Error;
export type ServerError = Error;
export type HTTPError = Error & { HTTPCode: number, Data: any, }; 	
export type NotImplementedError = Error;	 	
	
-- # Modules
local tableUtil = require('./BetterTable');
 
-- # Pre-constructed classes
local validTypes = {
	Error = { {'Message', ''}, {'Code', 0}, {'Trace', ''}, {'Context', {}}, };	 			
	TypeError = { Base = 'Error',	{'Expected', ''}, {'Got', ''}, }; 		
	NilError = { Base = 'Error',	{'Variable', ''}, };
	DependencyError = { Base = 'Error',	{'Missing', ''}, }; 
	PermissionError = { Base = 'Error',	{'Resource', ''}, {'ExpectedLevel', 1}, {'GotLevel', 0}, };
	NetworkError = { Base = 'Error',	{'Expected', Enum.RunContext.Server}, {'Got', Enum.RunContext.Client}, };	 
	FormatError = { Base = 'Error', };			
	ConcurrencyError = { Base = 'Error', };
	ParseError = { Base = 'Error', };
	ServerError = { Base = 'Error', };
	HTTPError = { Base = 'Error', {'HTTPCode', 200}, {'Data', {}} };		 
	NotImplementedError = { Base = 'Error', };	
};

----------------------------------------------------------------------------------------------------------------------------
 
-- # Object handling
local WritesLocked = false;			
local Errors = setmetatable({}, { 
	--__newindex = function(table: {},	index: string, value: any): any
	--	if WritesLocked then warn(`Can't access {index}`); end;
	--	table[index] = value;
	--end,	
	__metatable = {},		
}); 		  	
	 	
-- @desc - Creates a new <code>Error</Code> class and returns the constructor.	 
-- @param ErrorName* - The name to create the <code>Error</code> with.
-- @param Base - The format of the <code>Error</code> object. Read the docs for more info.	 
-- @return - <Error> 
function Errors.class(ErrorName: string, Base: Error & {Base: string}): Error
	WritesLocked = false; 
	Base = Base or validTypes.Error;	 		
	if Errors[ErrorName] then return Errors[ErrorName]; end; 
	local Class: Error? = {}; 
	Class.__index = Class;			
	Class.__type = ErrorName;		
	Class.__tostring = function(err: Error): string return getmetatable(err.Context).__message; end;	 
	Class.__identifier = true;
	function Class.new(Message: string, Code: number?, Context: {} | nil, ...): Error? 	
		Context = Context or {};
		assert(typeof(Context) == "table", 'Argument #3 "Context" must be of type "table"'); 	
		Context.Type = ErrorName;		 
		local __meta = {   
			__message = `{ErrorName or Context.Type or 'Error'}{ 
			if typeof(Message) == "string" then `: {Message}` else ''}{
			if typeof(Code) == "number" then	` ({Code})` else ''}`,		 	
		};		   
		task.spawn(function(): () if Context.Except then warn(__meta.__message); else error(__meta.__message, 0); end; end); 	
		setmetatable(Context, __meta); 	
		local Object = table.clone(Base);			 
		local Base_: string = Object.Base;	 	
		if Base_ then
			for Index: string, Value: any in validTypes[Base_] do
				if Index ~= "Base" then table.insert(Object, Value); end; 	
			end;	 		
		end;
		Object.Base = nil;	 	 	 	 
		local Supplier = table.pack(...); Supplier.n = nil;	 
		local Keys, Formatted = tableUtil.new(Object):keysArrayFormat();	 	 							
		for Index: number, Key: string? in Keys do      
			local Value: any = Supplier[Index]; 
			if Value ~= nil then 		 
				assert(typeof(Value) == typeof(Formatted[Key]), `Argument #{Index + 3} "{Key}" must be of type "{typeof(Formatted[Key])}"`);
				Object[Key] = Value;
			end; 		 
		end;	 
		Object.Trace = debug.traceback();	  	
		return setmetatable(Object, Class);	 
	end;		
	-- @desc - Returns <code>true</code> if the <code>Error</code> object's class matches the <code>_</code> parameter.	 
	-- @param _ - The class name to check.
	-- @return - <boolean> 		 
	function Class:IsA(_: string): boolean	return getmetatable(self).__type == _; end; 	
	-- @desc - Returns the type of the <code>Error</code> object.				 
	-- @return - <string>
	function Class:GetType(): string return getmetatable(self).__type; end;	 			 
	-- @desc - Prints and returns the traceback of the <code>Error</code>.	 	
	-- @return - <string>	
	function Class:Trace(): string?
		local traceback: string? = self.Trace; 	
		if traceback then
			print(traceback); return traceback;
		end; 		
	end;	 
	 
	local create = setmetatable({ new = Class.new, }, { __identifier = true, });	 
	if ErrorName ~= "Error" then
		Errors[ErrorName] = create;
	end;	 
	WritesLocked = true; 		
	return create;	 		
end;

-- # Initiate pre-constructed classes 		
for Type: string,	Contents: (Error?) & {Base: string} in validTypes do
	Errors.class(Type, Contents);
end;	    			
			 
local Error: Error = Errors.class("Error", validTypes.Error); 		
-- @desc - Creates a new <code>Error</code> object. 		 
-- @param Message - The message to show on the <code>Error</code>.	
-- @param Code - An optional error code to include in the message.
-- @param Context - Optional parameters to include in the object. Can contain anything.
-- @return - <Error> 
function Errors.new(Message: string, Code: number?, Context: {} | nil, ...): Error 	
	return Error.new(Message, Code, Context, ...);	 			
end; 			 	
--[[ @desc - If the provided <code>value</code> resolves to <code>false</code> or <code>nil</code>, this will create a new Error object with the
<code>errorType</code> type, and passes along the <code>...</code> parameters to the Error declaration.]]
-- @param value*<a> - The value to be asserted against. 
-- @param errorType* - The type of the <code>Error</code> object to be created.	
-- @param message - An optional message to include in the <code>Error</code>.	  
-- @param @spread - The optional parameters to pass to the <code>Error</code> object. 	 
-- @return - <a> 	
function Errors.assert<a>(value: a, errorType: Error, message: string?, ...:any): a 	
	assert(getmetatable(errorType).__identifier and typeof(errorType.new) == "function", 'Argument #2 "errorType" must be a valid Error constructor'); 
	if value == nil or value == false then			
		(errorType or Error).new(message or 'Assertion failed', nil, nil, ...);	 	
	else return value;
	end;	 
end; 
-- @desc - Returns a list of all created <code>Error</code> classes, and their constructors. 		
-- @return - <{[string]: Error}>
function Errors.list(): {[string]: Error} 		
	local list: {[string]: Error?} = {};
	for Index: string, Value: any? in Errors do
		if typeof(Value) == "table" and (getmetatable(Value)or{}).__identifier then		 
			list[Index] = Value;			
		end;	 
	end;	
	return list or {};	 
end;  
  
-- # Return
WritesLocked = true; 
return Errors;
