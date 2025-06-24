export type Region = {
	Min: Vector3, -- minimum
	Max: Vector3, -- maximum		
	Point: Vector3, -- center (avg) 																			
	new: (Min: Vector3, Max: Vector3) -> Region,		 
	within: (self: Region, Target: Vector3) -> boolean,
};		
local IsBetween = function(value: number, value1: number?, value2: number): boolean? 	
	return value >= value1 and value <= value2; end; 	
local Region: Region = {};
Region.__index = Region; 		
Region.new = function(Min: Vector3, Max: Vector3): Region	
	return setmetatable({
		Min = Min,
		Max = Max,
		Point = (Min + Max) / 2		
	}, Region);		 
end;	 
-- Checks if the target vector is within the range. 	
function Region.within(self: Region, Target: Vector3): boolean	 	
	return 
		IsBetween(Target.X, self.Min.X, self.Max.X) and
		IsBetween(Target.Y, self.Min.Y, self.Max.Y) and
		IsBetween(Target.Z, self.Min.Z, self.Max.Z);	
end; 		
-- Returns the center point among a list of regions.	 
function Region.center(r1: Region, ...: Region?): Vector3	
	local list = table.pack(...); 	
	list.n = nil;
	table.insert(list, 1, r1);	 
	local total = Vector3.zero;	
	for _, v: Region? in list do
		total += v.Point;
	end;		 
	return total / #list;	 			
end;	
return Region;	 
