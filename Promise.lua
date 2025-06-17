--[[------------------------------------------------------------------------------------------------------------------------
 
	--- Promise Module ---	
	
	Created by Lincoln Touw
	V1.0 6/10/2025		  	 			
		
	---------------------
	
	## LJPM created by Lincoln Touw 6/03/2025	
	## https://lincolntouw.github.io/ljpm-rbx			
	
	--- LJPackageManager Information: --- 
	<PackageInfo>
		<ModuleName>Promise</ModuleName>	 
		<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
		<ModuleVersion>1.0</ModuleVersion>	
		<PackageDependencies>
			<Package>
				<Name>QuickEvent</Name>
				<Version>1.0</Version>	
			</Package>
			<Package>
				<Name>EnumList</Name> 
				<Version>1.0</Version>
			</Package>
		</PackageDependencies>	 
	</PackageInfo>	 
	
--]]------------------------------------------------------------------------------------------------------------------------

export type Promise = {
	status: () -> PromiseStatus,  
	andThen: (callback: (data: { any }, status: string) -> ()) -> (),      
	catch: (callback: (error: string) -> ()) -> (),      
	clear: () -> (),  
	reject: () -> (),  
	resolve: () -> (),  
};       
export type PromiseStatus = PromiseStatus;       

----------------------------------------------------------------------------------------------------------------------------

local QuickEvent = require(script.Parent:WaitForChild('QuickEvent'));
local EnumList = require(script.Parent:WaitForChild('EnumList'));	  

local Promise = {};         
Promise.__index = Promise;	 		
local PromiseStatus = EnumList.new('PromiseStatus', {
	"Pending",
	"Resolved",
	"Rejected",
	"Failed",   
	"TimedOut",
	"Cancelled",			
	"Unknown",        
});      

----------------------------------------------------------------------------------------------------------------------------

-- Returns a new Promise object.         
Promise.new = function(executor: (resolve: () -> (), reject: () -> ()) -> (), mute: boolean?): Promise
	local event = QuickEvent.new();          
	local onClose = QuickEvent.new(); 
	local errorCatch = QuickEvent.new();   
	local thenCatch = QuickEvent.new();     
	local cleaning = QuickEvent.new();  
	 
	local state, finished = PromiseStatus.Pending, false;  
	local parameters: {};        
	
	local resolve = function(...): ()  	
		event.fire(PromiseStatus.Resolved, ...);       	
	end;	
	local reject = function(...): ()
		event.fire(PromiseStatus.Rejected, 'Promise was rejected', ...);	 	 	 							 
	end;
	
	event.on(function(mode: PromiseStatus, ...: any): ()      
		if finished then error('Promise has already been closed'); end;   
		if mode == PromiseStatus.Resolved then
			finished = true; state = PromiseStatus.Resolved; 
			parameters = table.pack(...); parameters.n = nil
			onClose.fire();
		elseif mode == PromiseStatus.Rejected then
			finished = true; state = PromiseStatus.Rejected;
			parameters = table.pack(...); parameters.n = nil;	
			local errorMessage = parameters[1]; table.remove(parameters, 1);	 
			errorCatch.fire(errorMessage, unpack(parameters)); 		   
			onClose.fire();                                   
			finished = true;
		end;    			    
		thenCatch.fire(mode, ...);  
		event.discard();     
		--print(mode,PromiseStatus.Rejected,EnumList:GetEnumList('PromiseStatus').Rejected,mode==PromiseStatus.Rejected);				
		if (not mute) and (mode == PromiseStatus.Rejected) then task.spawn(function(): () error('Promise was rejected', 0); end); end;    
	end);     	

	local class: Promise = {};                  
	-- Returns the current status of the Promise. (EnumList.PromiseStatus)    
	function class.status(): PromiseStatus return state; end;
	-- Calls the provided function once the Promise closes, even if it was rejected. Does not get called when the Promise fails.  
	function class.finally(callback: (status: PromiseStatus, ...params) -> ()): () 
		thenCatch.on(function(mode: string, ...: any): ()   
			callback(mode, ...); 
		end);        
		return class;	
	end;        
	-- Calls the provided function once the Promise is resolved.    
	function class.andThen(callback: (...params) -> ()): Promise?  
		local linkedPromise: Promise = Promise.new(function(res, rej): ()
			thenCatch.on(function(mode: string, ...: any): ()   
				if mode == PromiseStatus.Resolved then res(callback(...)); else rej(); end;	           
			end); 	         
		end, true);	      
		return linkedPromise;  	
	end;      	 
	-- Waits for the Promise to resolve, and returns any associated data.		
	function class.await(): ...any	
		local data = table.pack(thenCatch.wait());	 
		data.n = nil;
		data[1] = nil;	 
		return unpack(data);	
	end;	
	-- Invokes a callback when the Promise yields an error or is rejected.
	-- Returns another Promise for chaining.	  
	function class.catch(callback: (error: string, ...data) -> ()): ()  
		local linkedPromise: Promise = Promise.new(function(res, rej): ()
			errorCatch.on(function(error: string, ...: any): ()   
				coroutine.wrap(callback)(error, ...);		 
				res(error, ...);	 				 	 		 	  
			end);	                           		 	   	
		end);	  
		return linkedPromise;
	end;   
	-- Deprecated, do not use. Predecessor to Promise.reject.  
	@deprecated function class.cancel(): () reject(); end;         
	-- Rejects the Promise remotely, therefore halting execution of the Promise.
	function class.reject(): () reject(); return class; end;     
	-- Resolves the Promise remotely, therefore halting execution of the Promise.         
	function class.resolve(): () resolve(); return class; end;          
	-- Clears all traces of the Promise ever existing.
	function class.clear(): () cleaning.fire(); end;    
	cleaning.on(function(): ()
		thenCatch.discard();
		onClose.discard();
		errorCatch.discard(); 
		cleaning.discard();
		class = nil;  
		event.discard();    
	end);      
	onClose.on(cleaning.fire); 		

	task.defer( function(): () 
		local success: boolean, data: any = xpcall(executor, function(err: string?): () 
			class.reject(err);	 			    	  	 
			-- task.spawn(function() error(`Promise yielded error before closing: "{err}"\n(traceback: {debug.traceback()})`, 0); end);    
		end, resolve, reject);   	
	end);   

	return class;              
end;          	

-- Returns a new Promise that gets resolved when the provided event is fired.
function Promise.fromEvent(event: RBXScriptSignal): Promise?    
	return Promise.new(function(resolve, reject): ()
		event:Connect(resolve);                               
	end);              
end;      

-- Executes a list of Promises, then returns the output from the one that finishes first, and immediately cancelling the rest.
-- This function yields thread execution until the first Promise is closed.    
function Promise.race(Promises: { Promise }): any 
	local onFinish: QuickEvent = QuickEvent.new();      
	for index: number, Promise: Promise in Promises do
		Promise.andThen(function(...): () 
			onFinish.fire(...);    
		end);   
	end;   
	local results: {} = table.pack(onFinish.wait());	
	results.n = nil;	
	for index: number, Promise: Promise in Promises do Promise.clear(); end;
	return unpack(results);   
end;  

----------------------------------------------------------------------------------------------------------------------------	

return Promise;	
