--[[------------------------------------------------------------------------------------------------------------------------
 
	--- Errors Module ---	
	
	Created by Lincoln Touw  
	V1.0 6/17/2025 			
	
	---------------------
	
	## LJPM created by Lincoln Touw 6/03/2025	
	## https://lincolntouw.github.io/ljpm-rbx			
	
	--- LJPackageManager Information: --- 
	<ModuleName>BetterErrors</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>1.0</ModuleVersion>			
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
	NotImplementedError = { Base = 'Error', };	
};

----------------------------------------------------------------------------------------------------------------------------
 
-- # Object handling
local Errors = {};	

local Error: Error = {};
Error.__index = Error;	
Error.__type = 'Error';	 
Error.__identifier = true;
Error.__tostring = function(err: Error): string return getmetatable(err.Context).__message; end; 

-- @desc - Creates a new <code>Error</code> object. 		 
-- @param Message - The message to show on the <code>Error</code>.	
-- @param Code - An optional error code to include in the message.
-- @param Context - Optional parameters to include in the object. Can contain anything.
-- @return - <Error> 
function Error.new(Message: string, Code: number?, Context: {} | nil): Error 	
	Context = Context or {};			 
	assert(typeof(Context) == "table", 'Argument #3 "Context" must be of type "table"'); 	 	 
	local __meta = {   
		__message = `{Context.Type or 'Error'}{ 
		if typeof(Message) == "string" then `: {Message}` else ''}{
		if typeof(Code) == "number" then	` ({Code})` else ''}`,		 	
	};		  
	task.spawn(function(): () error(__meta.__message, 0); end); 	
	setmetatable(Context, __meta); 		
	return setmetatable({ 
		Message = Message, Code = Code, Context = Context,
		Trace = debug.traceback(),	
	}, Error); 												
end;		    
-- @desc - Returns <code>true</code> if the <code>Error</code> object's class matches the <code>_</code> parameter.	 
-- @param _ - The class name to check.
-- @return - <boolean> 		 
function Error:IsA(_: string): boolean	return getmetatable(self).__type == _; end;
-- @desc - Returns the type of the <code>Error</code> object.				 
-- @return - <string>
function Error:GetType(): string return getmetatable(self).__type; end;	 
	 
-- @desc - Creates a new <code>Error</Code> class and returns the constructor.	 
-- @param ErrorName* - The name to create the <code>Error</code> with.
-- @param Base - The format of the <code>Error</code> object. Read the docs for more info.	 
-- @return - <Error> 
function Errors.class(ErrorName: string, Base: Error & {Base: string}): Error
	Base = Base or validTypes.Error;	 		
	if Errors[ErrorName] then return error(`Error Class "{ErrorName}" already exists or is restricted`, 0);	end;
	local Class: Error? = {}; 
	Class.__index = Class;			
	Class.__type = ErrorName;		
	Class.__tostring = Error.__tostring; 
	Class.__identifier = true;
	function Class.new(Message: string, Code: number?, Context: {} | nil, ...): Error? 	
		Context = Context or {};
		assert(typeof(Context) == "table", 'Argument #3 "Context" must be of type "table"'); 	
		Context.Type = ErrorName;		 
		local Object = table.clone(Base);			 
		local Base_: string = tostring(Object.Base);	
		Object.Base = nil;	
		for Index: string, Value: any in validTypes[Base_] do
			if Index ~= "Base" then table.insert(Object, Value); end; 	
		end;	 		
		local BaseError: Error = Error.new(Message, Code, Context); 	 	 	 
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
	function Class:IsA(_: string): boolean	return getmetatable(self).__type == _; end; 	
	function Class:GetType(): string return getmetatable(self).__type; end;	 			 
	local create = { new = Class.new, };	 
	Errors[ErrorName] = create; 		
	return create;	 		
end;

-- # Initiate pre-constructed classes 		
for Type: string,	Contents: (Error?) & {Base: string} in validTypes do
	Errors.class(Type, Contents);
end;	    			

Errors.new = Error.new; 			 
--[[ @desc - If the provided <code>value</code> resolves to <code>false</code> or <code>nil</code>, this will create a new Error object with the
<code>errorType</code> type, and passes along the <code>...</code> parameters to the Error declaration.]]
-- @param value*<a> - The value to be asserted against. 
-- @param errorType* - The type of the <code>Error</code> object to be created.	
-- @param message - An optional message to include in the <code>Error</code>.	  
-- @param @spread - The optional parameters to pass to the <code>Error</code> object. 	 
-- @return - <a> 
Errors.assert = function<a>(value: a, errorType: Error, message: string?, ...:any): a 	
	assert(getmetatable(errorType).__identifier and typeof(errorType.new) == "function", 'Argument #2 "errorType" must be a valid Error constructor'); 
	if value == nil or value == false then			
		(errorType or Error).new(message or 'Assertion failed', nil, nil, ...);	 	
	else return value;
	end;	 
end;
  
-- # Return
return Errors; 	
