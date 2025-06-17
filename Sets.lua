-- Author: Lincoln Touw
-- Github: @lincolntouw  	
-- Made: 3/14/2025 		
-- Version: 1.0 

----------------------------------

-- types
export type Set = { number }; 	

-- range func	 
local function range(start: number, stop: number, step: number): () 	
	local a = {}; for i = start, stop, step do a[i] = i; end; return a; end;	 
 		 
-- sets
local Set = {};	
Set.__index = Set;

-- Creates a new set		
function Set.new(...: number): Set 	
	local a: Set? = {};	 	
	local p = table.pack(...); p.n = nil;	 
	for index: number, value: number in p do	 
		assert(typeof(value) == "number", "Invalid input.");	 	
		table.insert(a, value); 	  
	end;	
	return setmetatable(a, {
		__metatable = {},	
		__unm = function(t: Set): Set	
			local b = {}; for k, v in t do
				b[k] = -v;
			end;	
		end,
		__add = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v + (t1[k] or 0); end; return b;
		end,
		__sub = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v - (t1[k] or 0); end; return b;
		end,
		__mul = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v * (t1[k] or 0); end; return b;
		end,
		__div = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v / (t1[k] or 0); end; return b;
		end,
		__idiv = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v // (t1[k] or 0); end; return b;
		end,
		__pow = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v ^ (t1[k] or 0); end; return b;
		end,	
		__mod = function(t1: Set, t2: Set): Set? 		
			local b = {}; for k, v in t2 do b[k] = v % (t1[k] or 0); end; return b;	
		end, 		
		__eq = function(t1: Set, t2: Set): boolean 
			local sg = true; for k, v in t2 do
				if v ~= t1[k] then sg = false; break; end; end; 
			return sg;
		end,	
		__lt = function(t1: Set, t2: Set): boolean 
			return t1:sum() < t2:sum();
		end,	
		__le = function(t1: Set, t2: Set): boolean	 
			return t1:sum() <= t2:sum();	 
		end,
		__len = function(t: Set): number return #t; end,
		__tostring = function(t: Set): string return table.concat(t, ", "); end,
	})
end;		
-- Returns the sum of all numbers in the set.	 
function Set:sum(): number
	local s = 0; for k, v in self do s+= v; end; return s;
end;				  
-- Returns the average of the set.
function Set:average(): number	 
	return self:sum()	/ #self; 
end;			  
-- Returns the average of the set.
function Set:mean(): number	 
	return self:average();	  
end;	
-- Returns the median of the set.
function Set:median(): number	
	local odd: boolean = #self % 2 ~= 0;
	if odd then return self[math.ceil(#self / 2)]; else
	return (self[math.ceil(#self / 2)] + self[#self // 2]) / 2; end;	
end; 		 	
-- Returns the mode of the set. Inaccurate for multi-modal sets.	 
function Set:mode(): number
	local ns = {};	
	for k, v in self do ns[v] = (ns[v] or 0) + 1; end; 		
	local max, key = -1, 0; 		
	for k, v in ns do
		if v > max then key, max = k, v; end;
	end;	 		
	return key;
end; 		

-- Finds the largest number in the set. 	
function Set:max(): number return math.max(unpack(self)); end;
-- Finds the smallest number in the set. 	
function Set:min(): number return math.min(unpack(self)); end;
-- Calculates the difference between the smallest and largest number in the set.
function Set:range(): number return Set:max() - Set:min(); end; 			

-- Calculates the average squared difference from the mean.	 
function Set:variance(): number	
	local n, m = #self, self:average();		    	
	local sumSq = 0;
	for _, v in self do	 
		local d = v - m; 	 	
		sumSq += d * d; 		
	end
	return sumSq / n; 	
end;	 		
-- Standard deviation of the set.
function Set:stddev(): number	
	return math.sqrt(self:variance()); 		
end;	
-- Linear interpolation between ranks
function Set:percentile(p: number): ()
	local s = table.clone(self); table.sort(s); 	
	local n = #s; 	
	if n == 1 then return s[1]; end;	 
	local idx = p * (n - 1) + 1; 
	local lo, hi = math.floor(idx), math.ceil(idx);	 
	if lo == hi then return s[lo];
	else local frac = idx - lo; return s[lo] + frac * (s[hi] - s[lo]); end; 		
end; 	

-- Checks if the set contains `n`.
function Set:contains(n: number): boolean 	
	return table.find(self, n) ~= nil;			
end; 	
-- Counts how many times `n` appears in the set.
function Set:count(n: number): number 	
	local t = 0; for k, v in self do if v == n then t += 1; end; end; return t;
end;	  	
-- Filters the set where f(v) == true. 	 		
function Set:filter(f: (number) -> boolean): () 		 
	local c = {}; for k, v in self do
		if f(v) == true then table.insert(c, v); end;
	end; self:flush();	 	
	for k, v in c do self[k] = v; end; 			
end; 		
-- Identical to Set:filter, but returns a new set instead. 	
function Set:cfilter(f: (number) -> boolean): Set?   		
	assert(typeof(f) == "function", "Argument #1 'f' must be of type function.");
	local c = {}; for k, v in self do 
		if f(v) == true then table.insert(c, v); end;
	end; 	
	return Set.new(unpack(c));	 
end;	 		
-- Applies f(v) to each number.
function Set:map(f: (number) -> ()): () 	
	assert(typeof(f) == "function", "Argument #1 'f' must be of type function.");
	for k, v in self do
		self[k] = f(v);
	end;	 
end;	 	
-- Identical to Set:map, but returns a new set instead. 	
function Set:cmap(f: (number) -> ()): Set? 	
	assert(typeof(f) == "function", "Argument #1 'f' must be of type function.");
	local c = {};	
	for k, v in self do
		c[k] = f(v);
	end; 		
	return Set.new(unpack(c));	
end; 	

-- Shuffles the set in-place.	
function Set:shuffle(): () 	
	Random.new():Shuffle(self);
end;		 
-- Sorts the set in-place in ascending or descending order. 	
function Set:sort(ascending: boolean): () 	
	table.sort(self);
	if ascending then Set:reverse(); end; 			
end;	 		  	
-- Appends `n` copies of the set onto the end of the set. (in-place)	
function Set:rep(n: number): Set		
	for i in range(1, n, 1) do 		
		for k, v in self do self:push(v); end
	end;	  
end;	  	 
-- Clears the set.
function Set:flush(): () 	
	for k, v in self do self[k] = nil; end; 		
end;
-- Reverses the set in-place.
function Set:reverse(): ()
	local c = table.clone(self);	
	for k, v in self do self[k] = c[#c - k]; end; 										
end;	 	
-- Returns a tuple of the set's contents. 	
function Set:content(): ...number
	return unpack(self);	 
end; 	
-- Returns a copy of the set. 		
function Set:copy(): Set	 
	return Set.new(self:content());	 		
end;	
-- Returns the size of the set. 	
function Set:length(): number return #self; end;	
-- Append a number to the set. 	
function Set:push(n: number): () table.insert(self, n); end;  				

return { new = Set.new, };	 
