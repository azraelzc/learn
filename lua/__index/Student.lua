local Person = require("Person")

local Student = Person:extend()
function Student:new(name, score)
	print("===Student:new==")
    Student.super.new(self, name)
    self.score = score
end

function Student:print()
    Student.super.print(self)
    print("score is ", self,self.score)
end

return Student