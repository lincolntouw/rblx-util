local Queue = {}
Queue.__index = Queue   
export type Queue = setmetatable<{}, typeof(Queue)>     

function Queue.new(): Queue        
	local updated = Instance.new("BindableEvent")                
	local self = {
		Changed = updated.Event,        
		Items = {},
		Size = 0,                   
		__updated = updated,
	}
	self.Changed:Connect(function(): ()
		self.Size = #self.Items     
		local front = self.Items[1]
		if front then
			front.__event:Fire()     
			if front.__callback then
				front.__callback()
				self:remove(1)                    
			end
		end  
	end)     
	return setmetatable(self, Queue)
end

function Queue:Destroy(): ()    
	self.__updated:Destroy()        
	self = nil
end         

------------------------------------------------------------------------        

local QueueItem = {}         
QueueItem.__index = QueueItem   
export type QueueItem = setmetatable<{}, typeof(QueueItem)>              

function QueueItem.new(
	parentQueue: Queue, 
	callback: () -> boolean?            
): QueueItem   
	local symbol: userdata = newproxy()  
	local reached = Instance.new("BindableEvent")       
	return setmetatable({
		__id = symbol,               
		__parent = parentQueue,   
		__callback = callback,  
		__event = reached,   
		ReachedFront = reached.Event,
	}, QueueItem)      
end     

function QueueItem:remove(): ()     
	self.__parent:remove( table.find(self.__parent.Items, self) )
	self = nil                       
end             

------------------------------------------------------------------------        

function Queue:push(
	onReached: () -> (boolean, ...any),     
	at: number?
): QueueItem   
	if at and at > self.Size + 1 then
		return error(`Cannot create item outside of queue limits ({at} > {self.Size + 1})`)     
	end 
	local this = QueueItem.new(self, onReached)          
	table.insert(self.Items, at or #self.Items + 1, this)      
	self.__updated:Fire()
	return this  
end           

function Queue:skip(amount: number): ()     
	if type(amount) ~= "number" then return error("Argument 1 \"amount\" expected type number") end             
	if amount < 1 then return error("Amount must be positive") end                                
	for _ = 1, amount do                
		table.remove(self.Items, 1)         
	end 
	self.__updated:Fire()
end         

function Queue:remove(at: number): ()
	if type(at) ~= "number" then return error("Argument 1 \"at\" expected type number") end             
	if at < 1 then return error("Pos must be positive") end          
	table.remove(self.Items, at)        
	self.__updated:Fire()
end     

------------------------------------------------------------------------   

return Queue :: Queue   
