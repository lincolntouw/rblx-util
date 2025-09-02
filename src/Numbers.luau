--!strict 		
--[[------------------------------------------------------------------------------------------------------------------------
 
	--- NumberUtil Module ---	
	
	Created by Lincoln Touw
	V1.0 6/28/2025		  	 			
			   
	--- LJPackageManager Information: ---	 
	<PackageInfo>
		<ModuleName>NumberUtil</ModuleName>	 
		<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
		<ModuleVersion>1.0</ModuleVersion>	
		<PackageDependencies/>		 	 
	</PackageInfo>	 
	
--]]------------------------------------------------------------------------------------------------------------------------
	 	
local Numbers = {}; 				

----------------------------------------------------------------------------------------------------------------------------
 
-- Rounds a number to the nearest specified decimal place. 		
-- <strong>decimalPlaces</strong>: The decimal place to round to. (ex n = 1.29 and decimalPlaces = 1 returns 1.3) 		
Numbers.toFixed = function(
	n: number, 
	decimalPlaces: number?
): number	 		
	decimalPlaces = decimalPlaces or 1;
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`);	 	
	assert(type(decimalPlaces) == "number", `Argument #2 "decimalPlaces" expected type number, got {typeof(decimalPlaces)}`);	 	
	if decimalPlaces == 0 then return math.floor(n); end; 		
	return math.round(n * 10 ^ decimalPlaces) / 10 ^ decimalPlaces; 		
end; 	 
 
-- Abbreviates a number in "1.42k" format. 	 	
-- <strong>decimalPlaces</strong>: How many decimal places to include.
-- <strong>capitalize</strong>: Determines if the suffix should be capitalized.	 
-- <strong>customAbbreviations</strong>: Specify a custom format for the function to use. Must be in {[base] = "suffix"} table format.
Numbers.abbreviate = function(	 
	n: number,
	decimalPlaces: number?,
	capitalize: boolean?,	 	
	customAbbreviations: {[number]: string}? 	
): string 		 		
	decimalPlaces = decimalPlaces or 1;
	capitalize = if capitalize == nil then false else capitalize;	 	
	customAbbreviations = customAbbreviations or {
		[1e3] = 'k',
		[1e6] = 'm',
		[1e9] = 'b',
		[1e12] = 't',
		[1e15] = 'qd',
		[1e18] = 'qn'  	
	}; 		
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`);	 	
	assert(type(decimalPlaces) == "number", `Argument #2 "decimalPlaces" expected type number, got {typeof(decimalPlaces)}`);	 	
	assert(type(capitalize) == "boolean", `Argument #3 "capital" expected type bool, got {typeof(capitalize)}`); 		
	assert(type(customAbbreviations) == "table", `Argument #4 "customAbbreviations" expected type table, got {typeof(customAbbreviations)}`);
	local bases: {number} = {}
	for base in customAbbreviations do table.insert(bases, base); end;		 
	table.sort(bases, function(a: number, b: number): boolean return a < b; end); 			
	local useSuffix: string, useBase: number = "", 1;	  			 
	for _, base: number in bases do 	
		if base <= n then 
			local suffix: string = customAbbreviations[base];		 
			useSuffix, useBase = suffix, base;
		end;		
	end; 		
	local formattedNumber: number = Numbers.toFixed(n / useBase, decimalPlaces); 		
	local formattedString: string = tostring(formattedNumber); 	 		
	return `{formattedString}{if capitalize then useSuffix:upper() else useSuffix:lower()}`;	 
end;	 	 		
-- Formats a number to "xB" format.
Numbers.byteFormat = function(
	n: number,
	decimalPlaces: number?,	 	
	capitalize: boolean?
): string		
	return Numbers.abbreviate(
		n,
		decimalPlaces,
		capitalize,
		{
			[1] = "b",					 
			[1024] = "kb",	 	
			[1024 ^ 2] = "mb",		
			[1024 ^ 3] = "gb",	 	
			[1024 ^ 4] = "tb",	 	
			[1024 ^ 5] = "pb",
			[1024 ^ 6] = "eb",			  	 	 	  
			[1024 ^ 7] = "zb",		
			[1024 ^ 8] = "yb",		
		}
	);	 		
end;	

-- Formats a number to "123,456" format, adding commas after every third digit. 	 	
Numbers.commaFormat = function(
	n: number
): string 		
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`);	 	
	local formatted: string = tostring(n); 	 
	while true do
		local f: string, k: number? = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2");	 	
		formatted = f; 		 
		if k == 0 then break; end;
	end;
	return formatted;	 	
end;	 	
 
-- Formats the specified seconds into a readable time string, such as "01:48".		 
-- <strong>sec</strong>: The amount of seconds to format.
-- <strong>useLetters</strong>: If true, uses a "1H46M23S" format. If false/nil, uses "01:46:23" format.	 	
Numbers.timeFormat = function(
	sec: number,		 
	useLetters: boolean?		
): string
	useLetters = not not useLetters;	 		
	assert(type(sec) == "number", `Argument #1 "sec" expected type number, got {typeof(sec)}`); 	 	
	local days: number = math.floor(sec / 86400);
	local hrs: number = math.floor((sec % 86400) / 3600);
	local mins: number = math.floor((sec % 3600) / 60);
	local secs: number = math.floor(sec % 60);
	local ms: number = math.floor((sec - math.floor(sec)) * 1000); 			 
	if useLetters then	 			    
		local str: string = ""; 		
		if days > 0 then str ..= string.format("%dD", days); end; 			
		if hrs > 0 or days >0 then str ..= string.format("%dH", hrs); end;
		if mins > 0 or hrs > 0 then str ..= string.format("%dM", mins); end;
		str ..= string.format("%dS", secs); 		
		if ms > 0 then str ..= string.format("%dMS", ms); end;
		return str; 		
	else
		local parts: {string} = {};
		if days > 0 then table.insert(parts, string.format("%02d", days)); end
		if hrs > 0 or days > 0 then table.insert(parts, string.format("%02d", hrs)); end;
		table.insert(parts, string.format("%02d", mins));
		table.insert(parts, string.format("%02d", secs)); 	 
		local result: string = table.concat(parts, ":"); 		
		if ms > 0 then
			result ..= "." .. string.format("%03d", ms);
		end; 
		return result;		 
	end
end; 	 			
-- Returns a formatted time string with the current time. 		
--Numbers.timestamp = function(
--	useLetters: boolean?
--): string
--	return Numbers.timeFormat(os.time(), useLetters);
--end;	

local function opTo(
	mode: string,
	n: number,
	interval: number
): number
	interval = interval or 1; 		
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`); 	 	
	assert(type(interval) == "number", `Argument #2 "interval" expected type number, got {typeof(interval)}`); 		 	
	return math[mode](n / interval) * interval;
end;	 	
-- Floors a number to the nearest multiple of <code>interval</code>. (ex n = 46 and interval = 10 returns 40)
Numbers.floorTo = function(
	n: number,
	interval: number
): number return opTo("floor", n, interval); end; 		
-- Rounds a number upwards to the nearest multiple of <code>interval</code>. (ex n = 46 and interval = 10 returns 50)
Numbers.ceilTo = function(
	n: number,
	interval: number
): number return opTo("ceil", n, interval); end; 		
-- Rounds a number to the nearest multiple of <code>interval</code>. (ex n = 46 and interval = 10 returns 50)
Numbers.roundTo = function(
	n: number,
	interval: number
): number return opTo("round", n, interval); end; 		 
						
Numbers.NaN = 0 / 0; 			 			
-- Checks if the input is a whole number.	 	
Numbers.isInt = function(
	n: number
): boolean 
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`); 	 	
	return n % 1 == 0;
end;	 	
-- Checks if the input is a number.	 		
Numbers.isNaN = function(
	n: number
): boolean 
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`); 	 	
	return (tonumber(n) ~= nil) or (n == 0 / 0); 		
end;	 		
-- Checks if a number is a prime number. 		
Numbers.isPrime = function(
	n: number
): boolean
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`); 	 	
	if n ~= math.floor(n) or n < 2 then return false; end;
	if n == 2 or n == 3 then return true; end;
	if n % 2 == 0 or n % 3 == 0 then return false; end;
	for i: number = 5, math.floor(math.sqrt(n)), 6 do
		if n % i == 0 or n % (i + 2) == 0 then return false; end;
	end; return true; 			 	 		  	 	 	 	 		
end;

-- Formats a number as a percentage. (ex n = 60 and total = 500 returns 12%) 		 		
Numbers.percentage = function(
	n: number,
	total: number,	
	decimalPlaces: number?
): string		 
	assert(type(n) == "number", `Argument #1 "n" expected type number, got {typeof(n)}`); 	 	
	assert(type(total) == "number", `Argument #2 "total" expected type number, got {typeof(total)}`); 	 	
	return if decimalPlaces then `{Numbers.toFixed(n / total * 100, decimalPlaces)}%` else `{n / total * 100}%`;	
end;  		
-- Performs linear interpolation on a number with the given alpha, min and max; as well as optional easing parameters. 		
Numbers.lerp = function(
	alpha: number,
	min: number,
	max: number,
	easing: Enum.EasingStyle?,			 
	direction: Enum.EasingDirection? 			
): number	 	
	direction = direction or Enum.EasingDirection.InOut;	  	 
	assert(type(alpha) == "number", `Argument #1 "alpha" expected type number, got {typeof(alpha)}`); 	 
	assert(type(min) == "number", `Argument #2 "min" expected type number, got {typeof(min)}`); 	 
	assert(type(max) == "number", `Argument #3 "max" expected type number, got {typeof(max)}`); 	 	
	if easing then			
		assert(typeof(easing) == "EnumItem" and easing:IsA("EasingStyle"), `Argument #4 "easing" expected type Enum.EasingStyle, got {typeof(easing)}`);
		assert(typeof(direction) == "EnumItem" and direction:IsA("EasingDirection"), `Argument #5 "direction" expected type Enum.EasingDirection, got {typeof(easing)}`);
		alpha = game:GetService("TweenService"):GetValue(alpha, easing, direction);	 	
	end;	 	 	
	return (1 - alpha) * min + alpha * max;	 	
end; 					
-- Finds the mean value over a set of numbers.	
Numbers.average = function(
	n: number,
	...: number
): number
	local set: {[number]: number, n: number} = table.pack(...);
	table.insert(set, 1, n);	 		
	local a: number = 0; 			
	for i: number = 1, #set do
		local v: number? = set[i];
		assert(type(v) == "number", `Numbers.average parameters can only contain numbers.`);		 
		a += v;
	end; 		
	return a / #set;		 
end;	 		
-- Finds the median value of a set of numbers.		
Numbers.median = function(
	n: number,
	...: number	 		
): number?		 
	local set: {[number]: number, n: number} = table.pack(...);
	table.insert(set, 1, n);	 
	if #set == 0 then return; end; 			
	table.sort(set); 			 
	
	local len: number = #set; 		
	local mid: number = math.floor(len / 2);
	if len % 2 == 1 then 
		return set[mid + 1]; 		
	else 
		return (set[mid] + set[mid + 1]) / 2;
	end; 			
end;	 
-- Calculates the sum of a set of numbers.		
Numbers.sum = function(
	n: number,
	...: number 				 		
): number?		 
	local set: {[number]: number, n: number} = table.pack(...);
	table.insert(set, 1, n);	   			
	local x: number = 0;	 			
	for i: number = 1, #set do x += set[i]; end; 		
	return x; 				
end;	  
-- Finds the ordinal for a specified number.	
Numbers.ordinal = function(
	n: number
): string	
	assert(type(n) == "number", `Argument #1 "n" must be of type number`);	 		
	local lastDigit = n % 10; 				
	local lastTwoDigits = n % 100;
	if lastDigit == 1 and lastTwoDigits ~= 11 then return `{n}st`;	 	
	elseif lastDigit == 2 and lastTwoDigits ~= 12 then return `{n}nd`;	 	
	elseif lastDigit == 3 and lastTwoDigits ~= 13 then return `{n}rd`; 		
	else return `{n}th`; end;
end;		 
-- Calcualtes the sign of a number. 		
Numbers.sign = function(
	n: number
): number	
	assert(type(n) == "number", `Argument #1 "n" must be of type number`);	 		
	return n > 0 and 1 or n < 0 and -1 or 0;
end;	 	
-- Pads a number	 	
Numbers.pad = function(
	n: number,
	len: number
): string
	assert(type(n) == "number", `Argument #1 "n" must be of type number`);	 		
	assert(type(len) == "number" and len > 0, `Argument #2 "len" must be a natural number`); 			 		
	return string.format(`%0{tostring(len)}d`, math.floor(n));			 	 	
end;
-- Calculates a factorial.	 		 		
Numbers.factorial = function(
	n: number 	
): number	
	assert(type(n) == "number" and n > 1 and n % 1 == 0, `Argument #1 "n" must be a natural whole number greater than or equal to 2`); 		 	 	
	local a: number = 1; 			
	for i: number = 2, n do a *= i; end; 		
	return a; 			
end; 
			
return Numbers;
