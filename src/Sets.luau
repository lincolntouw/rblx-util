-- Author: Lincoln Touw
-- Github: @lincolntouw  	
-- Created: 3/14/2025, Updated: 6/17/2025   		
-- Version: 1.4        	

------------------------------------------------------------------------------------------------------

-- types
export type Set = setmetatable<{number}, typeof(Set)>; 	

-- range func	 
local function range(start: number, stop: number, step: number): () 	
	local a = {}; for i = start, stop, step do a[i] = i; end; return a; end;	 
local abdiff = function(n1: number, n2: number): number return math.abs(n2 - n1); end; 			 

-- sets
local Set = {};	
Set.__index = Set;
--Set.__metatable = {};
Set.__unm = function(t: Set): Set	
	local b = {}; for k, v in t do
		b[k] = -v;
	end;	
end;
Set.__add = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v + (t1[k] or 0); end; return b;
end;
Set.__sub = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v - (t1[k] or 0); end; return b;
end;
Set.__mul = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v * (t1[k] or 0); end; return b;
end;
Set.__div = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v / (t1[k] or 0); end; return b;
end;
Set.__idiv = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v // (t1[k] or 0); end; return b;
end;
Set.__pow = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v ^ (t1[k] or 0); end; return b;
end;	
Set.__mod = function(t1: Set, t2: Set): Set? 		
	local b = {}; for k, v in t2 do b[k] = v % (t1[k] or 0); end; return b;	
end; 		
Set.__eq = function(t1: Set, t2: Set): boolean 
	local sg = true; for k, v in t2 do
		if v ~= t1[k] then sg = false; break; end; end; 
	return sg;
end;	
Set.__lt = function(t1: Set, t2: Set): boolean 
	return t1:sum() < t2:sum();
end;	
Set.__le = function(t1: Set, t2: Set): boolean	 
	return t1:sum() <= t2:sum();	 
end;
--Set.__len = function(t: Set): number return #t; end;
Set.__tostring = function(t: Set): string return table.concat(t, ", "); end;			

-- Creates a new set		
function Set.new(...: number): Set 	
	local a: Set? = {};	 	
	local p = table.pack(...); p.n = nil;	 
	for index: number, value: number in p do	 
		assert(typeof(value) == "number", "Invalid input.");	 	
		table.insert(a, value); 	  
	end;	
	return setmetatable(a, Set);	 
end;		

------------------------------------------------------------------------------------------------------

-- Returns the sum of all numbers in the set.	 
function Set:sum(): number
	local s = 0; for k, v in self do s+= v; end; return s;
end;				  
-- Returns the average of the set.
function Set:average(): number	 
	return self:sum() / #self; 
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
-- Creates a new set where each value is mapped on a range of 0-1. 		
function Set:normalize(): Set	
	local c: Set, min: number, max: number = Set.new(), self:min(), self:max(); 	
	for k, v in self do c:push((v - min) / (max - min)); 
	end; return c;
end; 		

------------------------------------------------------------------------------------------------------

-- Finds the largest number in the set. 	
function Set:max(): number return math.max(unpack(self)); end;
-- Finds the smallest number in the set. 	
function Set:min(): number return math.min(unpack(self)); end;
-- Calculates the difference between the smallest and largest number in the set.
function Set:range(): number return Set:max() - Set:min(); end; 			

------------------------------------------------------------------------------------------------------

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
-- Splits the set into `k` equal sized buckets and returns the cut points. For quartiles, use k=4. 		
function Set:quantiles(k: number): Set
	assert(k >= 2, "Argument #1 'k' must be >=2"); 	 	
	local c = {};
	for i in range(1, k - 1, 1) do 	
		c[i] = self:percentile(i / k); 			 
	end; return Set.new(unpack(c)); 		 	 			 
end;	 		
-- Returns a list of values that fall out of the interquartile range.	
function Set:outliers(): ({number}, {number}) 	 	
	local c = table.clone(self); c:sort();	 		 
	local q1, q3 = self:percentile(1/4), self:percentile(3/4); 		
	local iqr = q3 - q1;			 
	local lo, hi = (q1 - 1.5 * iqr), (q3 + 1.5 * iqr);
	local outliers, inliers = Set.new(), Set.new();	 	 
	for k, v in self do 	
		if v < lo or v > hi then outliers:push(v);
		else inliers:push(v); end; 		
	end; return outliers, inliers;	 	
end;

------------------------------------------------------------------------------------------------------	 	

-- Returns the index of the closest value to `index` that is equal to `value`. 	
function Set:nearest(index: number, value: number): number?
	local nrst, nrstDiff = nil, nil;	 		 
	for k, v in self do	
		if (v == value) and abdiff(k, index) < (nrstDiff or 0) then 			 	
			nrst, nrstDiff = k, abdiff(k, index);	 	
		end; end; return nrst; 		
end;	
-- Returns the index of the closest value to `index` that passes the function. 	
function Set:fnearest(index: number, f: (number) -> boolean): number? 	
	local nrst, nrstDiff = nil, nil;	 		 
	for k, v in self do	
		if f(v) and abdiff(k, index) < (nrstDiff or 0) then 			 	
			nrst, nrstDiff = k, abdiff(k, index);	 	
		end; end; return nrst; 			
end;	 		
-- Returns the first value and index that passes the function. 	 	 	
function Set:find(f: (number) -> boolean): (number, number) 			
	for k, v in self do	
		if f(v) then return v, k; end;
	end;	   	
end;	 		
-- Returns true if at least one value passes the function. 	 	
function Set:any(f: (number) -> boolean): boolean	
	for k, v in self do	
		if f(v) then return true; end; 	 		
	end;	 
	return false;	 		 	
end;	 
-- Returns true if all values pass the function. 	
function Set:all(f: (number) -> boolean): boolean	
	for k, v in self do
		if not f(v) then return false; end; 		
	end;	 
	return true;	
end;	 

------------------------------------------------------------------------------------------------------
 			
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

-- OPERATIONS ---------------------------------------------------------------------------------------- 	

-- Creates a copy of the set with all duplicate values removed.	 	
function Set:unique(): Set<gurt?> 
	local seen, c = {}, Set.new(); 	 
	for k, v in self do 	
		if not seen[v] then seen[v] = true; c:push(v); end;	 	 
	end; return c;
end;	 
-- Returns true if all elements of this set are present in `otherSet`. 	
function Set:isSubset(otherSet: Set): boolean? 	 
	for k, v in self do
		if otherSet[k] ~= v then return false; end;
	end; return true; 	
end;	 
-- Creates a new set populated with all values present in this set that are <i>not</i> present in `otherSet`. 	
function Set:opdiff(otherSet: Set): Set	
	local c: Set = Set.new();   
	for k, v in self do
		local i: number = table.find(otherSet, v);
		if not i then c:push(v); table.remove(otherSet, i); end; 	
	end; return c;			 	
end;	 
-- Creates a new set populated with all values present in <i>both</i> this set and `otherSet`.	 	
function Set:opintersect(otherSet: Set): Set	
	local c: Set = Set.new();	 
	for k, v in self do
		local i: number = table.find(otherSet, v);	 
		if i then c:push(v); table.remove(otherSet, i); end; 		
	end; return c;
end;	 
-- Merges this set with `otherSet`, with no duplicates.	 	
function Set:opunion(otherSet: Set): Set	
	local c: Set = Set.new();	 
	local seen = {};	 
	for k, v in self do seen[v] = true; end; 	
	for k, v in otherSet	do 
		if not seen[v] then c:push(v); seen[v] = true; end;	 
	end; return c;
end;	 
-- Appends `otherSet` onto the end of this set. 	
function Set:opmerge(otherSet: Set): Set	
	local c: Set = Set.new();	
	for k, v in self do c:push(v); end;
	for k, v in otherSet do c:push(v); end;
	return c;	
end;	  
 
------------------------------------------------------------------------------------------------------

-- Groups the set into buckets of a	fixed width. 		 
function Set:bin(width: number): {[number]: number} 	
	assert(width > 0, "Argument #1 'width' must be a positive value."); 	
	local bins: {[number]: number?} = {}; 	
	for k, v in self do
		local bin = math.floor(v / width);	 
		bins[bin] = bins[bin] or Set.new(); 	 
		bins[bin]:push(v);				  		
	end; return bins;	 
end;	  	 
-- Counts how many values fit into fixed-width buckets. 			
function Set:histogram(bins: {Set}): Set	 
	local	s: {Set} = Set.new() or {}; 		 
	for k = 1, table.maxn(bins) do 		
		s[k] = if bins[k] then bins[k]:length() else 0;			
	end; return s; 	
end;	 	


------------------------------------------------------------------------------------------------------
 		
-- Select a range of values from the set.
function Set:select(imin: number, imax: number?): (...number) 	
	local c = {}; table.move(self, imin, imax, 1, c);	 
	return Set.new(c);	  	 		
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
-- Cuts `n` values off of the left side of the set. 	
function Set:reduce(n: number): () 	
	for i in range(1, n, 1) do
		table.remove(self, 1);	 	
	end;		
end;	
-- Returns a tuple of the set's contents. 	
function Set:content(): ...number
	return unpack(self);	 
end; 	
-- Checks if the set contains `n`.
function Set:contains(n: number): boolean 	
	return table.find(self, n) ~= nil;			
end; 	
-- Returns the index of the first occurence of `n`, or nil if none. 		
function Set:indexOf(n: number, startAt: number?): number | nil? 	
	return table.find(self, n, startAt or 0); 	 	 
end;	
-- Returns a copy of the set. 		
function Set:copy(): Set	 
	return Set.new(self:content());	 		
end;	

------------------------------------------------------------------------------------------------------
 
-- Returns the size of the set. 	
function Set:length(): number return #self; end;	
-- Append a number to the set. 	
function Set:push(n: number): () table.insert(self, n); end;  				
-- Converts the set into a regular array. 	
function Set:arrayify(): {number}
	local a: {number} = {};
	for k, v in self do
		a[k] = rawget(self, k);
	end; return a;	 	
end; 


------------------------------------------------------------------------------------------------------
 	
return { new = Set.new, };	  
