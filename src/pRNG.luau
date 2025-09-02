local rng = {}

-- returns true if a random roll succeeds based on the given chance
-- uses roblox's 'Random' class (optionally seeded) to generate a number between 0–100,
-- and compares it against the chance value.
-- ex: rng.roll(25) has a ~25% chance to return true
function rng.roll(chance: number, seed: number?): boolean        
  return Random.new(seed):NextNumber() * 100 <= chance   
end

return rng
