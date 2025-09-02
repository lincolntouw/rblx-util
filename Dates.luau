-- JS-like date class   
-- Lincoln Touw 5/26/25
 
local Time = {}  

export type Date = {
	timestamp: number,   
	ToUniversal: (self: Date) -> Date,
	ToIso: (self: Date) -> string,
	ToDateString: (self: Date, locale: Locale?) -> string,
	ToTimeString: (self: Date, locale: Locale?) -> string,
	GetOffset: (self: Date) -> number,
	GetTimeZone: (self: Date) -> string,    

	GetMillisecond: (self: Date) -> number,    
	GetSecond: (self: Date) -> number,    
	GetMinute: (self: Date) -> number,    
	GetHour: (self: Date) -> number,    
	GetDay: (self: Date) -> number,    
	GetMonth: (self: Date) -> number,    
	GetYear: (self: Date) -> number,    

	GetClockTime: (self: Date) -> number,    

	SetMillisecond: (self: Date, value: number) -> number, 		    
	SetSecond: (self: Date, value: number) -> number, 		    
	SetMinute: (self: Date, value: number) -> number, 		    
	SetHour: (self: Date, value: number) -> number, 		    
	SetDay: (self: Date, value: number) -> number, 		    
	SetMonth: (self: Date, value: number) -> number, 		    
	SetYear: (self: Date, value: number) -> number, 		    
} 			 
export type Locale = -- supported locale types on roblox      
	"ar-001" | "de-de" | "en-150" |
"en-au" | "en-ca" | "en-gb" |
"en-nz" | "en-us" | "es-es" |
"es-mx" | "fr-ca" | "fr-fr" |
"it-it" | "ja-jp" | "ko-kr" |
"pt-br" | "pt-pt" | "ru-ru" |
"zh-cjv" | "zh-cn" | "zh-hans" |
"zh-hant" | "zh-hk" | "zh-tw" 		

local Date = {}
Date.__index = Date  
Date.__metatable = {}  
local function opOn(self: Date, other: (Date | number)?, operation: string?): Date | boolean
	local mod = type(other) == 'number' and other or other.timestamp
	if operation == "add" then self.timestamp += mod end
	if operation == "sub" then self.timestamp -= mod end
	if operation == "mul" then self.timestamp *= mod end
	if operation == "div" then self.timestamp /= mod end
	if operation == "idiv" then self.timestamp //= mod end
	if operation == "mod" then self.timestamp %= mod end
	if operation == "pow" then self.timestamp ^= mod end 		 

	if operation == "eq" then return self.timestamp == mod end
	if operation == "lt" then return self.timestamp < mod end 		
	if operation == "le" then return self.timestamp <= mod end  

	-- self.dt = DateTime.fromUnixTimestampMillis(self.timestamp) 
	return self		 	
end 		
Date.__call = function(self: Date) return Date.new(self.timestamp) end 		  		 	 
Date.__tostring = function(self: Date): string return self:toIso() or `{self:toDateString()} {self:toTimeString()}` end 		
Date.__add = function(...): Date return opOn(..., 'add') end
Date.__sub = function(...): Date return opOn(..., 'sub') end 	 	 			
Date.__mul = function(...): Date return opOn(..., 'mul') end
Date.__div = function(...): Date return opOn(..., 'div') end
Date.__idiv = function(...): Date return opOn(..., 'idiv') end
Date.__mod = function(...): Date return opOn(..., 'mod') end
Date.__pow = function(...): Date return opOn(..., 'pow') end
Date.__eq = function(...): Date return opOn(..., 'eq') end
Date.__le = function(...): Date return opOn(..., 'le') end
Date.__lt = function(...): Date return opOn(..., 'lt') end

local copy = function(s: Date): DateTime return DateTime.fromUnixTimestampMillis(s.timestamp) end
-- Creates a new <code>Date</code> object from the specified Unix timestamp (in milliseconds).
Date.new = function(unix_ms: number): Date return setmetatable({ timestamp = unix_ms, dt = DateTime.fromUnixTimestampMillis(unix_ms) }, Date) end
-- Creates a new <code>Date</code> object with the current Unix timestamp (in milliseconds). 			
Date.now = function(): Date return Date.new(DateTime.now().UnixTimestampMillis) end
local function trace(): string return `(@ {debug.traceback()})` end   
-- Creates a new <code>Date</code> object representing a Unix timestamp with the specified UTC offset (in hours, e.g. -4 for Eastern) 
Date.fromOffset = function(utc_offset_hrs: number): Date	 	
	if type(utc_offset_hrs) ~= 'number' then return error("\"utc_offset_hrs\" must be a valid number " .. trace(), 0) end  
	if utc_offset_hrs < -14 or utc_offset_hrs > 14 then return error("\"utc_offset_hrs\" must be a valid offset " .. trace(), 0) end 		 
	return Date.new( Date.now():ToUniversal().timestamp + utc_offset_hrs * 3600e3 )
end   		  
-- Returns a new <code>Date</code> object with the timestamp converted into UTC.
function Date:ToUniversal(): Date
	--local dx = self.dt:ToUniversalTime()
	--dx = DateTime.fromUniversalTime(
	--	dx.Year, dx.Month, dx.Day, dx.Hour, dx.Minute, dx.Second, dx.Millisecond ) 	
	return Date.new( self.timestamp - self:GetOffset() * 3600e3 )    		
end   
-- Returns an ISO8601 string.
function Date:ToIso(): string  
	return copy(self):ToIsoDate()
end 		 		 
-- Returns a formatted date string with an optional locale. (e.g. 'en-us' = 'July 28, 2025') 		
function Date:ToDateString(locale: Locale? | 'en-us'): string
	return copy(self):FormatLocalTime('LL', locale or 'en-us') 			 	 	
end
-- Returns a formatted time string with an optional locale. (e.g. 'en-us' = '12:11:51 PM') 			 
function Date:ToTimeString(locale: Locale? | 'en-us', use_24_hr_time: boolean?, suffix_seconds: boolean?): string
	return copy(self):FormatLocalTime(use_24_hr_time and `HH:mm{suffix_seconds and ':ss' or ''}` or `LT{suffix_seconds and 'S' or ''}`, 
		locale or 'en-us') 			 			 	 	
end 
-- Returns the UTC offset (in hours) of the <code>Date</code> object.
function Date:GetOffset(): number 		 	 	 		
	return tonumber( os.date('%z', self.timestamp / 1e3) ) / 100  	 			 
end    
-- Returns the time zone (if any) of the <code>Date</code> object.
function Date:GetTimeZone(): string | "unknown"	
	return os.date( '%Z', self.timestamp / 1e3 ) or "unknown" 	 	 	  
end   		

-- Returns the millisecond value (0 < X < 1000) of the <code>Date</code> object. 			
function Date:GetMillisecond(): number return copy(self):ToLocalTime().Millisecond end
-- Returns the seconds (0 < X < 60) of the <code>Date</code> object. 			
function Date:GetSecond(): number return copy(self):ToLocalTime().Second end
-- Returns the minute (0 < X < 60) of the <code>Date</code> object. 			
function Date:GetMinute(): number return copy(self):ToLocalTime().Minute end
-- Returns the hour (0 < X < 24) of the <code>Date</code> object. 			
function Date:GetHour(): number return copy(self):ToLocalTime().Hour end
-- Returns the day (1 < X < 31) of the <code>Date</code> object. 			
function Date:GetDay(): number return copy(self):ToLocalTime().Day end
-- Returns the month (0 < X < 12) of the <code>Date</code> object. 			
function Date:GetMonth(): number return copy(self):ToLocalTime().Month end
-- Returns the year of the <code>Date</code> object. 			
function Date:GetYear(): number return copy(self):ToLocalTime().Year end

-- Calculates the corresponding <code>ClockTime</code> property to be used for <code>game.Lighting</code>. 			
function Date:GetClockTime(): number return (((self.timestamp / 1000) % 86400) / 86400) * 24 end 	 		

local lim_modify = {
	Millsecond = 999, Second = 59, Minute = 59,   
	Hour = 23, Day = 31, Month = 12, Year = 9999,
}
local modifier = function(s: Date, k: string, v: number?): (Date?) 		 
	if v > lim_modify[k] then return error(`Invalid {k:lower()} value ({v} > {lim_modify[k]})`) end 	 
	local c = copy(s):ToLocalTime()
	if not c[k] then return error(`Could not find {k}`) end 	 			  	 			 
	c[k] = v 		 
	s.timestamp = DateTime.fromLocalTime(
		c.Year, c.Month, c.Day, c.Hour, c.Minute, c.Second, c.Millisecond	
	).UnixTimestampMillis  	    	 			
end    
-- Changes the millisecond value of the <code>Date</code> object. 			
function Date:SetMillisecond(value: number): () modifier(self, 'Millisecond', value) return self end
-- Changes the second value of the <code>Date</code> object. 			
function Date:SetSecond(value: number): () modifier(self, 'Second', value) return self end
-- Changes the minute value of the <code>Date</code> object.  			
function Date:SetMinute(value: number): () modifier(self, 'Minute', value) return self en
-- Changes the hour value of the <code>Date</code> object. 			
function Date:SetHour(value: number): () modifier(self, 'Hour', value) return self end
-- Changes the day value of the <code>Date</code> object. 			
function Date:SetDay(value: number): () modifier(self, 'Day', value) return self end
-- Changes the  month value of the <code>Date</code> object. 			
function Date:SetMonth(value: number): () modifier(self, 'Month', value) return self end
-- Changes the year value of the <code>Date</code> object. 			
function Date:SetYear(value: number): () modifier(self, 'Year', value) return self end

-- apply constructors
--for key: string, value: () -> ()? in Date do
--	if not key:match'__' then
--		Time[key] = value		 	  
--	end
--end   		
Time.new = Date.new
Time.now = Date.now  
Time.fromOffset = Date.fromOffset
return Time  
